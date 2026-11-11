# 荒野逐羊 · DM 备团

《荒野逐羊》（A Wild Sheep Chase）的 DM 备团 App，以 macOS 为主、适配 iPad，用于在 D&D 5E 跑团时快速查阅场景、NPC 与怪物资料。

## 素材

- `Sheep_Chase_FINAL.pdf` — 英文原版冒险
- `綿羊冒險記.pdf` — 中文译本
- `荒野逐羊_简体中文版.pdf` — 9 页简体中文排版版（含封面、地图与数据块）

## 内容包

- `content/` — YAML 源文件（4 场景、3 NPC、5 怪物、3 遭遇、23 规则、14 法术、2 手牌、13 flags、树屋地图与图钉）
- `schema/content-pack.schema.json` — JSON Schema
- `scripts/build_content.py` — 校验与构建，输出 `build/ContentPack.json` 与 `build/assets/`

## 原型

- `prototype/index.html` — 可点击 HTML 原型（开团库、场景、战斗、地图、图片导出、遮屏）

## App 工程

- `SheepChase.xcodeproj` — 原生 SwiftUI 双 target：`SheepChaseMac` 与 `SheepChasePad`
- `project.yml` — XcodeGen 工程定义；改动后运行 `xcodegen generate`
- `ARCHITECTURE.md` — 分层、数据流、文件大小与模块约定；当前单文件软上限 400 行、硬上限 500 行
- `Packages/SheepChaseCore` — Domain + Content（纯 Foundation）
- `Packages/SheepChasePersistence` — SwiftData `RunRecord` + `RunRepository`
- `Packages/SheepChaseUI` — Theme、字号、参考卡视图与图片资源
- `Packages/SheepChaseExport` — JSON/Markdown 导出、版本备份
- `Packages/SheepChaseBattleEngine` — 纯战斗状态机（先攻/HP/专注/骰子/撤销）
- `Packages/SheepChaseRunStore` — Application 层 RunStore
- `Packages/SheepChaseLibraryFeature` — 开团库/详情/Prep/About
- `Packages/SheepChaseSceneFeature` — 场景
- `Packages/SheepChaseBattleFeature` — 战斗
- `Packages/SheepChaseMapFeature` — 地图
- `Packages/SheepChaseInspectorFeature` — 检查器/队伍/便签/会话/安全
- `Packages/SheepChaseSearchFeature` — 全局搜索
- `Packages/SheepChaseGuideFeature` — DM 导读（摘要/引钩/背景/主持建议）
- `Packages/SheepChaseRunShellFeature` — Run 工作区/Sheet 路由/图片导出
- 最低系统：macOS 14 / iPadOS 17；数据用 SwiftData 本地持久化
- UI：macOS 原生 `NavigationSplitView` + toolbar + sidebar + inspector；场景/战斗用 `GroupBox`，不再自绘标题栏或 HTML 式卡片；主题纸面统一由 Parchment 背景提供
- 主题：整窗 PDF 羊皮纸背景 + 不透明阅读页；长文/数据块放在阅读页上，纹理留在页边、侧栏和 toolbar；`GroupBox` 改为书页式分节线


> 支持系统浅色/深色：浅色为纸页桌面，深色为深色桌面 + 浅色阅读页；关于页可调界面字号。

- 内容包资源：`build/ContentPack.json` 会同步到 `SheepChase/Resources/ContentPack.json`；原始图片同步到 `SheepChase/Resources/ContentAssets/`
- 测试：9 个 App `SheepChaseTests`；30 个 Package 单元测试；12 个 iPad `SheepChaseUITests`（含 DM 导读、速查、主页导航、开团操作、场景原文、怪物数据卡、角色卡、速查状态、模组选择与另存为模组）
- 内容校对记录：`CONTENT_REVIEW.md`
- 文件大小检查：`python3 scripts/check_swift_file_sizes.py`
- Package 测试：`./scripts/test_packages.sh`（或分别 `swift test --package-path Packages/<name> --disable-sandbox`）

构建：

```bash
xcodebuild -project SheepChase.xcodeproj -scheme SheepChaseMac \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SheepChase.xcodeproj -scheme SheepChaseMac \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath build/DerivedDataTests CODE_SIGNING_ALLOWED=NO test

xcodebuild -project SheepChase.xcodeproj -scheme SheepChasePad \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.6' \
  -derivedDataPath build/DerivedDataPad CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SheepChase.xcodeproj -scheme SheepChasePad \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.6' \
  -derivedDataPath build/DerivedDataPad CODE_SIGNING_ALLOWED=NO \
  -only-testing:SheepChaseUITests test
```

> 当前 DSH 环境需要在 Swift 编译时加 `-disable-sandbox` 才能运行宏插件；已写入 `project.yml`，普通 Xcode 环境可按需移除。

DEBUG 启动参数：`-demoRun`、`-demoScene` / `-demoScene3` / `-demoScene4`、`-demoBattle` / `-demoBattleActive`、`-demoMap`、`-demoNPC`、`-demoNotes`、`-demoHandout` / `-demoItem` / `-demoSafety` / `-demoImageExport`、`-demoSessions`、`-demoSearch`、`-demoSource`。

## 状态

MVP 功能闭环已实现：4 场景内容、NPC 卡、可平移/缩放地图、全局 ⌘K 速查、左下角分类速查/钉住、DM 改动批注（可无限追加）、自定义节拍（可编辑/删除）、自定义 NPC/怪物、自定义地图图钉、遭遇调整、怪物本场数值、我的模组（含导入/导出/覆盖）、通用骰子工具、队伍添加/编辑/移除、备团清单与逐场景备注、战斗筹备/先攻/轮次/HP 直改/临时 HP/参与者战斗笔记/扩展状态/专注/骰子/多目标/撤销，NPC 盟友参战、怪物动作直达规则/法术、场景怪物数据卡、聚会记录与本地快照、桌面安全页与 rest 记录、Run JSON/Markdown 导出与导入、图片单张/批量导出与分享、Run 重命名/归档/删除、删除全部数据二次确认、自动保存/重启恢复、版本升级自动备份。

下一步是一次真实 3–4 小时跑团，按 `PLAYTEST.md` 记录备团时间、查询时间、回合点击和数据安全。产品与技术结论见 `DISCUSSION.md`。
