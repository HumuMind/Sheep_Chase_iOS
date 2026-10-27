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

## 原型

- `prototype/index.html` — 可点击 HTML 原型（开团库、场景、战斗、地图、图片导出、遮屏）

## App 工程

- `SheepChase.xcodeproj` — 原生 SwiftUI 双 target：`SheepChaseMac` 与 `SheepChasePad`
- `project.yml` — XcodeGen 工程定义；改动后运行 `xcodegen generate`
- 最低系统：macOS 14 / iPadOS 17；数据用 SwiftData 本地持久化
- UI：macOS 原生 `NavigationSplitView` + toolbar + sidebar + inspector；场景/战斗用 `GroupBox`，不再自绘标题栏或 HTML 式卡片；主题纸面统一由 Parchment 背景提供
- 主题：整窗 PDF 羊皮纸背景（含 toolbar）+ AppIcon/封面/绵羊插画 + 暗红 AccentColor；侧栏、内容、检查器透明叠在纸面上；`GroupBox` 改为书页式分节线，状态色改为哑光

> 目前按浅色书页主题固定外观，深色模式留到后续单独适配。
- 内容包资源：`build/ContentPack.json` 会同步到 `SheepChase/Resources/ContentPack.json`

构建：

```bash
xcodebuild -project SheepChase.xcodeproj -scheme SheepChaseMac \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build

xcodebuild -project SheepChase.xcodeproj -scheme SheepChasePad \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.6' \
  -derivedDataPath build/DerivedDataPad CODE_SIGNING_ALLOWED=NO build
```

> 当前 DSH 环境需要在 Swift 编译时加 `-disable-sandbox` 才能运行宏插件；已写入 `project.yml`，普通 Xcode 环境可按需移除。

DEBUG 启动参数：`-demoRun`（直接进入周五团）、`-demoScene`（场景态）、`-demoBattle`（战斗筹备）、`-demoBattleActive`（演示战斗态）、`-demoNotes`（便签）。

## 状态

Vertical slice 已跑通：开团库、场景、队伍（添加玩家）、便签、战斗筹备、玩家先攻填写、怪物自动先攻、按轮次战斗、SwiftData 自动保存与重启恢复。地图/导出/分享、场景 3–4 内容等继续迭代。产品与技术结论见 `DISCUSSION.md`。
