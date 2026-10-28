# 架构说明

## 总览

这是一个 SwiftUI 应用工程 + 本地 Swift Package 模块，由 `project.yml` 通过 XcodeGen 生成两个 target：

- `SheepChaseMac`：macOS 14+
- `SheepChasePad`：iPadOS 17+

两个 target 共享同一套 App 源码和 Package。没有 Catalyst，也没有 “Designed for iPad”。

App target 现在只保留装配层：

```text
SheepChase/
  App/
    SheepChaseApp.swift      创建 ModelContainer/Repository/RunStore
    RootView.swift           开团库 ↔ 当前开团切换
    DemoSeed.swift           示例开团
  Content/
    ContentStore.swift       从 Bundle 解码 ContentPack
  Resources/
    ContentPack.json、ContentAssets、AppIcon/AccentColor

SheepChaseTests/             内容、导入导出、生命周期、会话等 App 级测试
SheepChaseUITests/            iPad 启动、场景工作区、全局搜索
```

## Packages

```text
Packages/
  SheepChaseCore/
    RunModels、ContentPack
  SheepChasePersistence/
    RunRecord、RunRepository
  SheepChaseExport/
    RunSnapshot、JSON/Markdown、RunBackupService
  SheepChaseBattleEngine/
    BattleEngine 纯战斗状态机
  SheepChaseUI/
    Theme、字号、参考卡、SheepChaseImages、图片资源
  SheepChaseRunStore/
    RunStore 及 Battle/Sessions/Export 扩展、AppVersion
  SheepChaseLibraryFeature/
    Library、详情、新建、Prep、About
  SheepChaseSceneFeature/
    SceneView、SceneDetailSections
  SheepChaseBattleFeature/
    BattleCenter/Select/Initiative/Active/Inspector/Components
  SheepChaseMapFeature/
    MapView
  SheepChaseInspectorFeature/
    Inspector、Party、AddPlayer、Rules、Notes、Sessions、Safety
  SheepChaseSearchFeature/
    GlobalSearchView
  SheepChaseGuideFeature/
    AdventureGuideView（DM 前置导读）
  SheepChaseRunShellFeature/
    RunView、RunExportDocument、ImageExport
```

### 依赖方向

```text
SheepChaseCore
  ├── SheepChasePersistence
  ├── SheepChaseExport          (Core + Persistence)
  ├── SheepChaseBattleEngine   (Core)
  ├── SheepChaseUI             (Core)
  └── SheepChaseRunStore       (Core + Persistence + Export + BattleEngine)

SheepChaseRunStore
  ├── SheepChaseLibraryFeature  (also SearchFeature)
  ├── SheepChaseSceneFeature
  ├── SheepChaseBattleFeature
  ├── SheepChaseMapFeature
  ├── SheepChaseInspectorFeature (also BattleFeature)
  ├── SheepChaseSearchFeature
  ├── SheepChaseGuideFeature
  └── SheepChaseRunShellFeature  (Scene + Battle + Map + Inspector + Search + Guide + Export)

App
  └── LibraryFeature / RunShellFeature / RunStore / Core / Persistence / Export / UI
```

Feature 包不允许反向依赖 App，也不允许 RunShell 被其他 Feature 依赖。

## 分层职责

### Core

- `PartyMember`、`StickyNote`、`BattleState`、`RunSession`、`RunStateSnapshot` 等纯 Codable 值类型。
- `ContentPack` 只读 Codable 模型。
- 不依赖 SwiftUI、SwiftData。

### Persistence

- `RunRecord`：SwiftData `@Model`，每团一条记录。
- `RunRepository`：fetch/insert/delete/save。
- 复杂状态仍用 JSON Data 保存，迁移和导出更直接。

### Export

- `RunSnapshot`、JSON 编解码、Markdown 导出。
- `RunBackupService`：版本升级时写入 Application Support，保留最近 3 份。
- 不依赖 SwiftUI；App 的 `RunExportDocument` 才提供 `FileDocument`。

### BattleEngine

- 选择、先攻、开战、轮次、HP/临时 HP、状态、专注、骰子、多目标、撤销。
- 纯 `BattleState` 输入输出，不依赖 SwiftData/SwiftUI。
- `RunStore+Battle` 只负责取/存 Run、checkpoint、toast。

### UI

- `Theme`、`AppTextSize`、`BookGroupBoxStyle`、`BookPaperBackground`、`readingPage`。
- `NPCSheetView`、`MonsterSheetView`、Handout/Item/Rule/Spell 参考卡。
- `SheepChaseImages` 提供 Package bundle 内的 Cover/Map/Sheep/Parchment。
- App 的 Asset Catalog 只保留 AppIcon/AccentColor。

### RunStore

- `@MainActor @Observable` 的 Application 层。
- 初始化注入 repository/content/appVersion/backupDirectory/seed：
  ```swift
  RunStore(
      repository: ...,
      content: ...,
      appVersion: AppVersion.short,
      backupDirectory: ...,
      seed: { DemoSeed.make(content: content) }
  )
  ```
- 负责开团生命周期、导航、队伍、便签、场景备注、战斗协调、会话、导出协调。
- 不包含 SwiftUI；不直接读取 Bundle 或写死 Application Support 路径。

### Feature 包

- `LibraryFeature`：开团库、详情、新建、备团清单、About。
- `SceneFeature`：场景正文、节拍、分支、flags、遭遇、DM 备注，以及节拍右上角的原文弹框（PDF 风格单列排版）。
- `BattleFeature`：战斗入口、选择、先攻、战斗、右侧战斗检查器。
- `MapFeature`：地图平移/缩放与图钉。
- `InspectorFeature`：队伍/战斗/便签 tab、添加玩家、会话、安全页；原“速查”tab 已移到左下角速查面板。
- `SearchFeature`：全局搜索；Library 与 RunShell 共用。
- `GuideFeature`：DM 前置导读；Library 与 RunShell 共用。
- QuickReference：左下角面板，按人物/怪物/物品/法术/规则折叠分类；点击标签弹详情；钉住后置顶，并按 Run 持久化。RunShell 在场景正文顶部放常驻导读横幅，场景列表顶部放“开始之前”入口，顺序对应模组书的前置内容。
- `RunShellFeature`：RunView、Sheet 路由、导出文档、图片导出和左下角速查面板。
- 跨 Feature 的 Sheet 路由集中在 RunShell；Scene 通过闭包发出打开 NPC/Handout/Rule/Spell 的请求。

## 数据流

```text
YAML content
  → build_content.py 校验/生成 ContentPack.json
  → App bundle + ContentStore.load()
  → SheepChaseCore.ContentPack
  → RunStore + SheepChasePersistence.RunRecord
  → BattleEngine / Export
  → Feature / UI SwiftUI 视图
  → RunRepository.save()
```

Open/import/export 都通过 RunStore；Feature 视图通过 `@Environment(RunStore.self)` 读取状态。

## 文件大小约定

目标：常规 Swift 文件 ≤ 400 行，硬上限 500 行。

当前最大的几个文件：

| 文件 | 行数 |
|---|---:|
| `Packages/SheepChaseRunShellFeature/.../QuickReferencePanel.swift` | 364 |
| `Packages/SheepChaseRunStore/.../RunStore.swift` | 369 |
| `Packages/SheepChaseSceneFeature/.../SceneDetailSections.swift` | 353 |
| `Packages/SheepChaseBattleFeature/.../BattleActiveView.swift` | 347 |
| `Packages/SheepChaseRunShellFeature/.../RunView.swift` | 346 |
| `Packages/SheepChaseRunShellFeature/.../ImageExportView.swift` | 301 |
| `Packages/SheepChaseBattleEngine/.../BattleEngine.swift` | 240 |

检查：

```bash
python3 scripts/check_swift_file_sizes.py
```

脚本超过 500 行失败，超过 400 行警告。

## 测试

Package 测试（23 个）：

- Core 3
- Persistence 2
- UI 2
- Export 3
- BattleEngine 4
- RunStore 1
- LibraryFeature 1
- SceneFeature 1
- BattleFeature 1
- MapFeature 1
- InspectorFeature 1
- SearchFeature 1
- GuideFeature 1
- RunShellFeature 1

App 测试：

- 9 个 `SheepChaseTests`
- 9 个 iPad `SheepChaseUITests`（含 DM 导读、速查钉住/详情、主页导航、开团操作、场景原文、怪物数据卡与角色卡）

命令：

```bash
./scripts/test_packages.sh
xcodebuild -project SheepChase.xcodeproj -scheme SheepChaseMac \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath build/DerivedDataTests CODE_SIGNING_ALLOWED=NO test
xcodebuild -project SheepChase.xcodeproj -scheme SheepChasePad \
  -configuration Debug -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.6' \
  -derivedDataPath build/DerivedDataPad CODE_SIGNING_ALLOWED=NO \
  -only-testing:SheepChaseUITests test
```

## 已知取舍

- Public API 变宽：RunStore 和 Feature View 的 init 多为 public。
- SwiftUI `@Observable` 仍通过具体 `RunStore` 注入，而不是协议 existential；协议层只在服务/测试边界使用。
- 复杂 Run 状态仍以 JSON Data 存在 `RunRecord`，不是完全规范化的 SwiftData 关系。
- Feature smoke test 只验证 View 可构造；真实渲染由 iPad UI 测试和手工跑团覆盖。
- 真实 3–4 小时跑团仍是最终验收。
