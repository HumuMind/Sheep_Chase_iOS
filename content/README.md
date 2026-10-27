# 内容包（Schema Spike）

这是 C1/C2 的最小验证内容包：用 YAML 维护，构建时校验并生成 App 读取的 `build/ContentPack.json`。

当前覆盖：场景 1–2、古兹遭遇、夏恩布莱特 NPC 卡、专注规则卡、动物交谈法术卡、卷轴手牌、4 个 flags、树屋地图 asset 与图钉。

## 结构

```text
content/
  manifest.yaml
  adventure.yaml
  flags.yaml
  scenes/*.yaml
  npcs/*.yaml
  monsters/*.yaml
  encounters/*.yaml
  rules/*.yaml
  spells/*.yaml
  handouts/*.yaml
  items/      # 可选，当前为空
  maps/*.yaml
  assets/*.yaml + 图片
schema/content-pack.schema.json
scripts/build_content.py
```

## 校验与构建

```bash
python3 scripts/build_content.py --check   # 只校验
python3 scripts/build_content.py           # 校验并写 build/ContentPack.json + build/assets/
```

依赖：Python 3、`PyYAML`、`jsonschema`。构建会把 `content/assets/` 下的图片复制到 `build/assets/`。

## 约定

- ID 使用稳定 slug（如 `scene-1`、`finethir-shinebright`），不随排序变化。
- 实体之间只存 ID 引用；校验脚本会检查引用、场景顺序和图片文件。
- 玩家可见字段与 DM-only 字段分开：`publicDescription` / `secrets`、`playerText` / `dmText`、图钉 `dmOnly`。
- 地图图钉坐标使用 0–1 的归一化值；导出图片时不烧录图钉，图钉只存在于 App 内。
- 分支只是提示卡；`requiresFlag` 由运行时判断，内容包不执行逻辑。
- `manifest.usage` 当前为 `personal`，对应 C4 的个人自用边界。
- 不手改 `build/ContentPack.json`；它是生成物且被 git 忽略。

## 下一步

补齐场景 3–4、诺克/床龙雏龙、其余地图/图片资产，并继续扩充规则卡。
