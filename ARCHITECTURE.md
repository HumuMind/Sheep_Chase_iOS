# 架构说明

## 总览

这是一个 SwiftUI 应用工程 + 3 个本地 Swift Package，由 `project.yml` 通过 XcodeGen 生成两个 target：

- `SheepChaseMac`：macOS 14+
- `SheepChasePad`：iPadOS 17+

两个 target 共享同一套 App 源码与 Package，不维护两套业务逻辑。没有 Catalyst，也没有 “Designed for iPad”。

```text
SheepChase/
  App/          入口、RootView、版本设置、App 级协调
  Content/      ContentStore（从 Bundle 读取 ContentPack.json）
  Persistence/  RunStore 及其扩展、RunExport、版本备份
  Features/     场景、战斗、开团库、检查器、地图、导入导出等视图
  Resources/    ContentPack.json、ContentAssets、AppIcon/AccentColor

Packages/
  SheepChaseCore/
    Sources/SheepChaseCore/       Run/Battle/Session 值类型 + ContentPack 模型
    Tests/SheepChaseCoreTests/
  SheepChasePersistence/
    Sources/SheepChasePersistence/ RunRecord、RunRepository
    Tests/SheepChasePersistenceTests/
  SheepChaseUI/
    Sources/SheepChaseUI/         Theme、字号、参考卡、图片资源
    Tests/SheepChaseUITests/

SheepChaseTests/   内容、导入导出、生命周期、会话、战斗逻辑
SheepChaseUITests/ iPad 启动、场景工作区、全局搜索
```

## 分层

### Packages

**SheepChaseCore**（Foundation）

- `RunModels`：`PartyMember`、`StickyNote`、`BattleState`、`BattleCombatant`、`RunSession`、`RunStateSnapshot` 等纯 Codable 值类型。
- `ContentPack`：只读内容模型；不包含 Bundle 加载，加载器在 App 的 `ContentStore`。
- 所有 App/其他包需要的类型、属性、初始化器都是 public。

**SheepChasePersistence**（Core + SwiftData）

- `RunRecord`：SwiftData `@Model`，一条记录代表一次独立开团。
- `RunRepository`：包住 `ModelContext` 的 fetch/insert/delete/save。
- 不包含 `RunStore`、UI 导航或导出视图；这些仍在 App。

**SheepChaseUI**（Core + SwiftUI）

- `Theme`、`AppTextSize`、`BookGroupBoxStyle`、`BookPaperBackground`、`readingPage` 等设计系统。
- `NPCSheetView`、`MonsterSheetView`、`Handout/Item/Rule/SpellSheetView` 等只读参考卡。
- `SheepChaseImages` 提供 Package bundle 内的 Cover/Map/Sheep/Parchment 图片。
- Assets 随 Package 资源构建；App 不再保留这些 imageset（仅保留 AppIcon/AccentColor）。

### App

- `SheepChaseApp` 创建 `ModelContainer`、加载内容包、构造 `RunStore`。
- `RootView` 负责“开团库 ↔ 当前开团”两层切换、字号环境和全局外观。
- `SheepChase/Content/ContentStore` 从 App bundle 定位 `ContentPack.json` 并解码。
- `RunStore`：`@MainActor @Observable` 的应用状态/协调层，负责当前开团、导航、队伍、便签、战斗、会话、导出等。按功能拆成扩展：
  - `RunStore.swift`：状态、生命周期、导航、队伍、便签、场景备注、持久化
  - `RunStore+Battle.swift`：战斗筹备、先攻、轮次、HP、专注、骰子、撤销
  - `RunStore+Sessions.swift`：聚会记录、快照、安全设置、Run 管理
  - `RunStore+Export.swift`：JSON/Markdown 导出、导入、版本备份
  - `RunStore+Seed.swift`：示例开团种子
- `RunExport` 仍在 App，负责 `RunSnapshot` 的 FileDocument/图片文件名等 App 级导出细节。

这不是严格 MVVM：没有为每个视图再套一层 ViewModel。`RunStore` 相当于 app-level state/service，视图通过 `@Environment(RunStore.self)` 和 `@Bindable RunRecord` 直接读写。这样代码少、行为直接，但 `RunStore` 必须按功能拆文件，避免变成上帝对象。

### Features

- 一个功能一个文件/一组文件：场景、战斗、图书馆、检查器、地图、导出、会话、安全页等。
- 纯展示组件放在同功能文件内；跨页面复用的组件单独拆出（如 `BattleComponents`、`ReferenceSheet`）。
- 长文件优先按“屏幕/职责”拆，而不是机械地每个小 View 一个文件。

## 数据流

```text
YAML content
  → build_content.py 校验/生成 ContentPack.json
  → App bundle + ContentStore.load()
  → SheepChaseCore.ContentPack（只读）
  → RunStore + SheepChasePersistence.RunRecord（每团独立状态）
  → SheepChaseUI / App SwiftUI 视图
  → SheepChasePersistence.RunRepository.save()
```

- 修改 Run 后立即编码并保存；SwiftData 负责本地持久化。
- JSON/Markdown 导出是“当前 Run 的状态快照”，不是内容包副本。
- 自动备份在 App/内容版本变化时写入本机 Application Support，导入时创建新 Run，不覆盖旧记录。

## 文件大小约定

目标：**常规 Swift 文件 ≤ 400 行**，最多不超过 500 行。

当前（Package 抽取后）最大的几个文件：

| 文件 | 行数 |
|---|---:|
| `Features/RunView.swift` | 378 |
| `Persistence/RunStore.swift` | 351 |
| `Features/SceneDetailSections.swift` | 350 |
| `Features/BattleActiveView.swift` | 344 |
| `Persistence/RunStore+Battle.swift` | 329 |
| `Packages/SheepChaseCore/.../RunModels.swift` | 328 |
| `Packages/SheepChaseCore/.../ContentPack.swift` | 283 |
| `Packages/SheepChaseUI/.../ReferenceSheet.swift` | 247 |

检查：

```bash
python3 scripts/check_swift_file_sizes.py
swift test --package-path Packages/SheepChaseCore --disable-sandbox
swift test --package-path Packages/SheepChasePersistence --disable-sandbox
swift test --package-path Packages/SheepChaseUI --disable-sandbox
```

脚本在文件超过 500 行时失败，超过 400 行时给出警告。

## 已知取舍

- 为让 slice 尽快可跑，`RunRecord` 用 JSON Data 保存队伍/便签/战斗/安全/会话等复杂值，而不是全部拆成 SwiftData 关系。优点是迁移和导出一致；缺点是数据库层不可按字段查询。
- 两个 target 共享文件夹而不是独立 Swift Package；目前规模下更简单，后续要复用或严格模块化时再拆。
- UI 测试目前覆盖 iPad 的进入工作区和全局搜索，不覆盖每个弹层；复杂交互主要靠单元测试和 XCUITest 基础路径。
- `SheepChaseUI` 的资源随 Package bundle 走；App 的 Asset Catalog 只保留 AppIcon/AccentColor。
- 依赖方向：`Core ← Persistence`，`Core ← UI`，App 依赖三者；不允许 Package 反向依赖 App。
- 内容包校验、Package/App 单元测试、UI 测试都需要在本地跑；真实跑团仍是最终验收。
