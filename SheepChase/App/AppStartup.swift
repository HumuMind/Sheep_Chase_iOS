import Foundation
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SwiftData

/// 启动阶段需要显式处理失败的步骤：SwiftData 容器、内容包、备份。
@MainActor
enum AppStartup {
    struct Ready {
        let container: ModelContainer
        let store: RunStore
    }

    static func make() -> Result<Ready, StartupFailure> {
        do {
            let container = try ModelContainer(for: RunRecord.self)
            let content = try ContentStore.load()
            let repository = RunRepository(context: container.mainContext)
            let backupDirectory = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
            let store = RunStore(
                repository: repository,
                content: content,
                appVersion: AppVersion.short,
                backupDirectory: backupDirectory,
                seed: { DemoSeed.make(content: content) }
            )
            store.createVersionBackupIfNeeded()
            return .success(Ready(container: container, store: store))
        } catch {
            return .failure(StartupFailure(message: error.localizedDescription))
        }
    }
}

struct StartupFailure: Error {
    let message: String
}
