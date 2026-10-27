# 荒野逐羊 · DM 备团

《荒野逐羊》（A Wild Sheep Chase）的 DM 备团 App，以 macOS 为主、适配 iPad，用于在 D&D 5E 跑团时快速查阅场景、NPC 与怪物资料。

## 素材

- `Sheep_Chase_FINAL.pdf` — 英文原版冒险
- `綿羊冒險記.pdf` — 中文译本
- `荒野逐羊_简体中文版.pdf` — 9 页简体中文排版版（含封面、地图与数据块）

## 内容包

- `content/` — YAML 源文件（当前：场景 1–2、古兹遭遇、NPC/规则/法术/手牌、树屋地图与图钉）
- `schema/content-pack.schema.json` — JSON Schema
- `scripts/build_content.py` — 校验与构建，输出 `build/ContentPack.json` 与 `build/assets/`

## 状态

MVP 规划完成，内容包 Schema spike 已落地；App 工程尚未创建。产品与技术结论见 `DISCUSSION.md`。
