# 内容包（Schema Spike）

这是 C1/C2 的最小验证内容包：用 YAML 维护，构建时校验并生成 App 读取的 `build/ContentPack.json`。

当前覆盖：完整 4 场景、3 张 NPC 卡（夏恩布莱特/诺克/古兹）、5 个怪物（含诺克与床龙雏龙）、3 个遭遇、22 张规则卡、14 个法术、卷轴/地图手牌、13 个 flags、树屋地图与 3 个图片资源，以及 `adventure.guide` 中的 8 节 DM 前置导读。

## 结构

```text
content/
  manifest.yaml
  adventure.yaml      # 含 guide（DM 前置导读）
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
- `adventure.guide` 是 DM 必读摘要，不替代场景正文、怪物/NPC 数据块与地图；导读由 App 的“DM 导读”入口呈现。
- `manifest.usage` 当前为 `personal`，对应 C4 的个人自用边界。
- 不手改 `build/ContentPack.json`；它是生成物且被 git 忽略。

## 校对

完整校对记录见根目录 `CONTENT_REVIEW.md`。本轮已对照 HTML/PDF 复核怪物数据、法杖规则、遭遇配置和场景流程；页码与独立二校仍列为跑团前检查项。

## 下一步

内容层已覆盖可完整跑团的场景 1–4，并加入前置 DM 导读。App 层的 NPC、地图、速查、导出/备份、安全页与战斗工具已接入；下一步是真实跑团验证。
