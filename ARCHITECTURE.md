# 架构说明

## 总览

这是一个单一 SwiftUI 应用工程，由 `project.yml` 通过 XcodeGen 生成两个 target：

- `SheepChaseMac`：macOS 14+
- `SheepChasePad`：iPadOS 17+

两个 target 共享 `SheepChase/` 下的同一套 Swift 源码，不维护两套业务逻辑。没有 Catalyst，也没有 “Designed for iPad”。

代码按职责分目录，但仍是单一 App module，没有拆成多个 Swift Package：

```text
SheepChase/
  App/          入口、RootView、Theme、版本/字号设置
  Content/      ContentPack 只读 Codable 模型与加载
  Domain/       Run/Battle/Session 等 Codable 值类型
  Persistence/  SwiftData RunRecord、RunRepository、RunStore、导入导出
  Features/     场景、战斗、图书馆、检查器、弹层等 SwiftUI 视图
  Resources/    ContentPack.json、原始图片、Asset Catalog
SheepChaseTests/   内容、导入导出、生命周期、会话、战斗逻辑
SheepChaseUITests/ iPad 启动、场景工作区、全局搜索
```

## 分层

### App

- `SheepChaseApp` 创建 `ModelContainer`、加载内容包、构造 `RunStore`。
- `RootView` 负责“开团库 ↔ 当前开团”两层切换、字号环境和全局外观。
- `Theme` 提供纸面、阅读页、暗色桌面、工具栏背景和字体。
- 原生 `NavigationSplitView` + `.inspector` 负责 macOS/iPad 的导航结构。

### Content

- `ContentPack` 是只读数据的 Codable 映射；不包含业务逻辑。
- 内容源仍然是 YAML，构建为 `ContentPack.json` 后打进 App。
- 内容版本固定在 `manifest.version`，开团记录只在 `RunRecord.contentVersion` 里保存版本号。

### Domain

- `PartyMember`、`StickyNote`、`BattleState`、`BattleCombatant`、`RunSession`、`RunStateSnapshot` 等是纯 Codable 值类型。
- 这些类型不依赖 SwiftUI 或 SwiftData，便于测试和导出。

### Persistence

- `RunRecord`：SwiftData `@Model`，一条记录代表一次独立开团。
- `RunRepository`：包住 `ModelContext` 的 fetch/insert/delete/save，避免 Store 直接散落 SwiftData API。
- `RunStore`：`@MainActor @Observable` 的应用状态与服务层，负责当前开团、导航、队伍、便签、战斗、会话、导出等。它按功能拆成扩展：
  - `RunStore.swift`：状态、生命周期、导航、队伍、便签、场景备注、持久化
  - `RunStore+Battle.swift`：战斗筹备、先攻、轮次、HP、专注、骰子、撤销
  - `RunStore+Sessions.swift`：聚会记录、快照、安全设置、Run 管理
  - `RunStore+Export.swift`：JSON/Markdown 导出、导入、版本备份
  - `RunStore+Seed.swift`：示例开团种子

这不是严格 MVVM：没有为每个视图再套一层 ViewModel。`RunStore` 相当于 app-level state/service，视图通过 `@Environment(RunStore.self)` 和 `@Bindable RunRecord` 直接读写。这样代码少、行为直接，但 `RunStore` 必须按功能拆文件，避免变成上帝对象。

### Features

- 一个功能一个文件/一组文件：场景、战斗、图书馆、检查器、地图、NPC、导出、会话、安全页等。
- 纯展示组件放在同功能文件内；跨页面复用的组件单独拆出（如 `BattleComponents`、`ReferenceSheet`）。
- 长文件优先按“屏幕/职责”拆，而不是机械地每个小 View 一个文件。

## 数据流

```text
YAML content
  → build_content.py 校验/生成 ContentPack.json
  → Bundle + ContentStore.load()
  → ContentPack（只读）
  → RunStore + SwiftData RunRecord（每团独立状态）
  → SwiftUI 视图
  → RunRepository.save()
```

- 修改 Run 后立即编码并保存；SwiftData 负责本地持久化。
- JSON/Markdown 导出是“当前 Run 的状态快照”，不是内容包副本。
- 自动备份在 App/内容版本变化时写入本机 Application Support，导入时创建新 Run，不覆盖旧记录。

## 文件大小约定

目标：**常规 Swift 文件 ≤ 400 行**，最多不超过 500 行。

当前（重构后）最大的几个文件：

| 文件 | 行数 |
|---|---:|
| `Features/RunView.swift` | 375 |
| `Persistence/RunStore.swift` | 348 |
| `Features/SceneDetailSections.swift` | 347 |
| `Features/BattleActiveView.swift` | 341 |
| `Persistence/RunStore+Battle.swift` | 326 |

检查：

```bash
python3 scripts/check_swift_file_sizes.py
```

脚本在文件超过 500 行时失败，超过 400 行时给出警告。

## 已知取舍

- 为让 slice 尽快可跑，`RunRecord` 用 JSON Data 保存队伍/便签/战斗/安全/会话等复杂值，而不是全部拆成 SwiftData 关系。优点是迁移和导出一致；缺点是数据库层不可按字段查询。
- 两个 target 共享文件夹而不是独立 Swift Package；目前规模下更简单，后续要复用或严格模块化时再拆。
- UI 测试目前覆盖 iPad 的进入工作区和全局搜索，不覆盖每个弹层；复杂交互主要靠单元测试和 XCUITest 基础路径。
- 内容包校验、单元测试、UI 测试都需要在本地跑；真实跑团仍是最终验收。
