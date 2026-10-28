#!/usr/bin/env python3
"""Validate the YAML content source and build a bundled ContentPack.json.

Usage:
    python3 scripts/build_content.py --check
    python3 scripts/build_content.py
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[1]
CONTENT = ROOT / "content"
SCHEMA = ROOT / "schema" / "content-pack.schema.json"
DEFAULT_OUT = ROOT / "build" / "ContentPack.json"

COLLECTIONS = (
    "scenes",
    "npcs",
    "monsters",
    "encounters",
    "items",
    "handouts",
    "maps",
    "rules",
    "spells",
)

REF_FIELDS = {
    "npcIds": "npcs",
    "encounterIds": "encounters",
    "handoutIds": "handouts",
    "ruleIds": "rules",
    "spellIds": "spells",
    "mapIds": "maps",
    "itemIds": "items",
    "assetIds": "assets",
}


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def load_yaml(path: Path) -> Any:
    try:
        return yaml.safe_load(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"找不到文件：{path.relative_to(ROOT)}")
    except yaml.YAMLError as exc:
        fail(f"YAML 解析失败：{path.relative_to(ROOT)}\n{exc}")
    except OSError as exc:
        fail(f"读取失败：{path.relative_to(ROOT)}：{exc}")


def load_single(name: str) -> dict[str, Any]:
    path = CONTENT / name
    data = load_yaml(path)
    if not isinstance(data, dict):
        fail(f"{path.relative_to(ROOT)} 必须是 YAML 对象")
    return data


def load_collection(name: str, allow_empty: bool = False) -> list[dict[str, Any]]:
    directory = CONTENT / name
    paths = sorted(directory.glob("*.yaml"))
    if not paths:
        if allow_empty:
            return []
        fail(f"content/{name}/ 下没有 YAML 文件")
    result: list[dict[str, Any]] = []
    for path in paths:
        data = load_yaml(path)
        if not isinstance(data, dict):
            fail(f"{path.relative_to(ROOT)} 必须是单个 YAML 对象")
        result.append(data)
    return result


def load_flags() -> list[dict[str, Any]]:
    path = CONTENT / "flags.yaml"
    data = load_yaml(path)
    if not isinstance(data, list):
        fail("content/flags.yaml 必须是 YAML 列表")
    return data


def build_pack() -> dict[str, Any]:
    scenes = load_collection("scenes")
    scenes.sort(key=lambda scene: scene.get("order", 0))

    pack: dict[str, Any] = {
        "manifest": load_single("manifest.yaml"),
        "adventure": load_single("adventure.yaml"),
        "scenes": scenes,
        "npcs": load_collection("npcs"),
        "monsters": load_collection("monsters"),
        "encounters": load_collection("encounters"),
        "items": sorted(load_collection("items", allow_empty=True), key=lambda item: item["id"]),
        "handouts": load_collection("handouts"),
        "maps": load_collection("maps", allow_empty=True),
        "rules": load_collection("rules"),
        "spells": load_collection("spells"),
        "flags": load_flags(),
        "assets": sorted(load_collection("assets", allow_empty=True), key=lambda asset: asset["id"]),
    }

    for key in ("npcs", "monsters", "encounters", "handouts", "maps", "rules", "spells", "flags", "assets"):
        pack[key].sort(key=lambda item: item["id"])

    return pack


def validate_schema(pack: dict[str, Any]) -> None:
    schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)
    errors = sorted(
        validator.iter_errors(pack),
        key=lambda error: list(error.absolute_path),
    )
    if not errors:
        return

    print("内容包 Schema 校验失败：", file=sys.stderr)
    for error in errors:
        path = "/".join(str(part) for part in error.absolute_path) or "$"
        print(f"  - {path}: {error.message}", file=sys.stderr)
    raise SystemExit(1)


def validate_references(pack: dict[str, Any]) -> list[str]:
    errors: list[str] = []

    ids: dict[str, set[str]] = {
        key: {item["id"] for item in pack[key]} for key in COLLECTIONS
    }
    ids["flags"] = {item["id"] for item in pack["flags"]}
    ids["assets"] = {item["id"] for item in pack["assets"]}

    # 每个类型内唯一，并检查跨类型冲突。
    seen: dict[str, str] = {}
    for kind, values in ids.items():
        if len(values) != len(pack[kind]):
            errors.append(f"{kind}: 存在重复 ID")
        for value in values:
            if value in seen and seen[value] != kind:
                errors.append(f"ID '{value}' 同时出现在 {seen[value]} 和 {kind}")
            seen.setdefault(value, kind)

    def check_list(where: str, values: list[str] | None, kind: str) -> None:
        for value in values or []:
            if value not in ids[kind]:
                errors.append(f"{where}: 引用了不存在的 {kind} ID '{value}'")

    beat_ids: set[str] = set()
    branch_ids: set[str] = set()

    for scene in pack["scenes"]:
        where = f"scene '{scene['id']}'"
        for field, kind in REF_FIELDS.items():
            check_list(where, scene.get(field), kind)

        for beat in scene.get("beats", []):
            if beat["id"] in beat_ids:
                errors.append(f"{where}: beat ID 重复 '{beat['id']}'")
            beat_ids.add(beat["id"])
            beat_where = f"{where} / beat '{beat['id']}'"
            for field, kind in REF_FIELDS.items():
                check_list(beat_where, beat.get(field), kind)
            flag = beat.get("requiresFlag")
            if flag and flag not in ids["flags"]:
                errors.append(f"{beat_where}: 引用了不存在的 flags ID '{flag}'")
            if beat.get("type") == "encounter" and not beat.get("encounterIds"):
                errors.append(f"{beat_where}: encounter 类型必须提供 encounterIds")

        for branch in scene.get("branches", []):
            if branch["id"] in branch_ids:
                errors.append(f"{where}: branch ID 重复 '{branch['id']}'")
            branch_ids.add(branch["id"])
            flag = branch.get("requiresFlag")
            if flag and flag not in ids["flags"]:
                errors.append(
                    f"{where} / branch '{branch['id']}': 引用了不存在的 flags ID '{flag}'"
                )

    for encounter in pack["encounters"]:
        for combatant in encounter["combatants"]:
            if combatant["monsterId"] not in ids["monsters"]:
                errors.append(
                    f"encounter '{encounter['id']}': 引用了不存在的 monsters ID "
                    f"'{combatant['monsterId']}'"
                )

    for npc in pack["npcs"]:
        asset = npc.get("portraitAssetId")
        if asset and asset not in ids["assets"]:
            errors.append(f"npc '{npc['id']}': 引用了不存在的 assets ID '{asset}'")

    for handout in pack["handouts"]:
        asset = handout.get("imageAssetId")
        if asset and asset not in ids["assets"]:
            errors.append(f"handout '{handout['id']}': 引用了不存在的 assets ID '{asset}'")

    for map_data in pack["maps"]:
        if map_data["imageAssetId"] not in ids["assets"]:
            errors.append(
                f"map '{map_data['id']}': 引用了不存在的 assets ID "
                f"'{map_data['imageAssetId']}'"
            )

    for rule in pack["rules"]:
        check_list(f"rule '{rule['id']}'", rule.get("relatedSpellIds"), "spells")

    for asset in pack["assets"]:
        path = (CONTENT / asset["path"]).resolve()
        try:
            path.relative_to(CONTENT.resolve())
        except ValueError:
            errors.append(f"asset '{asset['id']}': 路径必须位于 content/ 内 '{asset['path']}'")
            continue
        if not path.is_file():
            errors.append(f"asset '{asset['id']}': 文件不存在 '{asset['path']}'")

    # 场景顺序与起始场景。
    scene_ids = [scene["id"] for scene in pack["scenes"]]
    scene_order = pack["adventure"]["sceneOrder"]
    if scene_order != scene_ids:
        errors.append(
            "adventure.sceneOrder 与场景文件顺序不一致："
            f"sceneOrder={scene_order}, scenes={scene_ids}"
        )
    if pack["adventure"]["startingScene"] not in scene_ids:
        errors.append("adventure.startingScene 不在 scenes 中")
    if pack["manifest"]["id"] != pack["adventure"]["id"]:
        errors.append("manifest.id 与 adventure.id 不一致")

    orders = [scene["order"] for scene in pack["scenes"]]
    if orders != list(range(1, len(orders) + 1)):
        errors.append(f"场景 order 必须从 1 连续递增，当前为 {orders}")

    return errors


def print_summary(pack: dict[str, Any]) -> None:
    print(
        "内容包 OK: "
        f"{len(pack['scenes'])} 个场景，"
        f"{len(pack['npcs'])} 个 NPC，"
        f"{len(pack['monsters'])} 个怪物，"
        f"{len(pack['encounters'])} 个遭遇，"
        f"{len(pack['handouts'])} 个手牌，"
        f"{len(pack['rules'])} 条规则，"
        f"{len(pack['spells'])} 个法术，"
        f"{len(pack['flags'])} 个 flag，"
        f"{len(pack['maps'])} 张地图，"
        f"{len(pack['assets'])} 个资源"
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Build/validate the content pack")
    parser.add_argument("--check", action="store_true", help="只校验，不写 JSON")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="输出 JSON 路径")
    args = parser.parse_args()

    pack = build_pack()
    validate_schema(pack)

    reference_errors = validate_references(pack)
    if reference_errors:
        print("内容包引用校验失败：", file=sys.stderr)
        for error in reference_errors:
            print(f"  - {error}", file=sys.stderr)
        raise SystemExit(1)

    print_summary(pack)

    if args.check:
        print("未写文件（--check）")
        return

    output = args.out.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(pack, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"写入：{output.relative_to(ROOT)}")

    app_resource = ROOT / "SheepChase" / "Resources" / "ContentPack.json"
    if app_resource.parent.is_dir():
        shutil.copy2(output, app_resource)
        print(f"同步 App 资源：{app_resource.relative_to(ROOT)}")

    for asset in pack["assets"]:
        source = (CONTENT / asset["path"]).resolve()
        destination = (output.parent / asset["path"]).resolve()
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        print(f"复制资源：{destination.relative_to(ROOT)}")

        app_assets = ROOT / "SheepChase" / "Resources" / "ContentAssets"
        if app_assets.parent.is_dir():
            app_assets.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, app_assets / source.name)


if __name__ == "__main__":
    main()
