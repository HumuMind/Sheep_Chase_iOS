# AGENTS.md

本仓库是《荒野逐羊》DM 备团 App（macOS 为主、适配 iPad）的项目。

## 开发讨论

- 产品与技术讨论及全部决策记录在 `DISCUSSION.md`（26 条，当前 MVP 基线）。
- 开发任何功能前，先读相关条目；实现不得与已定结论冲突。
- 若要改变已定结论，先更新 `DISCUSSION.md` 并写明原因，再改代码。

## 约定

- 当前无 App 工程；已有内容包源文件与校验脚本。
- PDF 是只读素材，不要修改或删除；简体中文版的排版源文件在 `source/adventure-zh-cn.html`（配图在 `source/assets/`）。
- 内容源在 `content/`（YAML），Schema 在 `schema/`；校验用 `python3 scripts/build_content.py --check`，构建用 `python3 scripts/build_content.py`。
- 不要手改 `build/ContentPack.json` 或 `build/assets/`；它们是生成物，且 `build/` 已被 git 忽略。
- App 计划采用原生 SwiftUI（macOS/iPadOS）+ SwiftData，最低 macOS 14 / iPadOS 17；详见 `DISCUSSION.md` 的 D1。
- 文档与界面使用简体中文。
- 实现以简洁、够用为准，避免过度设计。
