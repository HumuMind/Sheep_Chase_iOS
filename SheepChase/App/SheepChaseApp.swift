import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftData
import SwiftUI

@main
@MainActor
struct SheepChaseApp: App {
    private let container: ModelContainer
    @State private var store: RunStore

    init() {
        do {
            let container = try ModelContainer(for: RunRecord.self)
            self.container = container
            let store = RunStore(
                context: container.mainContext,
                content: ContentStore.load()
            )
            store.createVersionBackupIfNeeded(appVersion: AppVersion.short)
            _store = State(initialValue: store)
        } catch {
            fatalError("无法创建 SwiftData 容器：\(error)")
        }
    }

    var body: some Scene {
        WindowGroup("荒野逐羊") {
            RootView()
                .environment(store)
                .frame(minWidth: 1040, minHeight: 700)
        }
        .modelContainer(container)
        #if os(macOS)
        .defaultSize(width: 1380, height: 900)
        #endif
    }
}
