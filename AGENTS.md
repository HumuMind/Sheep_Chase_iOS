# AGENTS.md

本仓库是《荒野逐羊》DM 备团 App（macOS 为主、适配 iPad）的项目。

## 开发讨论

- 产品与技术讨论及全部决策记录在 `DISCUSSION.md`（26 条，当前 MVP 基线）。
- 开发任何功能前，先读相关条目；实现不得与已定结论冲突。
- 若要改变已定结论，先更新 `DISCUSSION.md` 并写明原因，再改代码。

## 约定

- 已有 SwiftUI App 工程：`SheepChase.xcodeproj`（`SheepChaseMac` / `SheepChasePad`），以及内容包、校验脚本和 HTML 原型。
- PDF 是只读素材，不要修改或删除；简体中文版的排版源文件在 `source/adventure-zh-cn.html`（配图在 `source/assets/`）。
- 内容源在 `content/`（YAML），Schema 在 `schema/`；当前为完整 4 场景、3 NPC、5 怪物、3 遭遇、22 规则、14 法术、2 手牌、13 flags。校验用 `python3 scripts/build_content.py --check`，构建用 `python3 scripts/build_content.py`；构建会同步 `SheepChase/Resources/ContentPack.json` 与 `ContentAssets/`。
- 不要手改 `build/ContentPack.json`、`build/assets/` 或 `SheepChase/Resources/ContentPack.json`；它们由脚本生成。
- App 为原生 SwiftUI（macOS/iPadOS）+ SwiftData，最低 macOS 14 / iPadOS 17；详见 `DISCUSSION.md` 的 D1。
- 工程由 `project.yml` 生成：改动后运行 `xcodegen generate`；`SheepChase.xcodeproj` 是生成物。
- 当前 DSH 环境需要 `OTHER_SWIFT_FLAGS` 中的 `-disable-sandbox` 让宏插件运行；不要无故移除。
- 构建命令见 README 的 App 工程一节；UI 变更后至少跑 macOS 与 iPad 模拟器 build。
- 单元测试：`xcodebuild -project SheepChase.xcodeproj -scheme SheepChaseMac -configuration Debug -destination 'platform=macOS' -derivedDataPath build/DerivedDataTests CODE_SIGNING_ALLOWED=NO test`。
- UI 使用原生 NavigationSplitView / toolbar / inspector / GroupBox；不要重新引入自绘标题栏或 HTML 式大卡片；主题背景统一使用 PDF 纸面。
- 内容校对记录在 `CONTENT_REVIEW.md`；真实跑团前先读 `PLAYTEST.md`，按其中的指标记录；不要在未备份当前 Run 的情况下开始测试。
- 可点击原型在 `prototype/index.html`，直接打开即可，无需构建。
- 文档与界面使用简体中文。
- 实现以简洁、够用为准，避免过度设计。
