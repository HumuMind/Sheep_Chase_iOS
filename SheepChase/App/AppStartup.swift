import Foundation
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftData

/// 启动阶段需要显式处理失败的步骤：数据目录、SwiftData 容器、内容包、备份。
@MainActor
enum AppStartup {
    struct Ready {
        let container: ModelContainer
        let store: RunStore
    }

    static func make() -> Result<Ready, StartupFailure> {
        if isRunningTests {
            return makeForTests()
        }
        do {
            let baseDirectory = try baseDirectory()
            let container = try makeContainer(baseDirectory: baseDirectory)
            let content = try ContentStore.load()
            let store = RunStore(
                repository: RunRepository(context: container.mainContext),
                content: content,
                appVersion: AppVersion.short,
                backupDirectory: baseDirectory,
                templateRepository: AdventureTemplateRepository(
                    fileURL: try LocalDataLayout.templateURL(in: baseDirectory)
                ),
                seed: { DemoSeed.makeForDemoLaunchIfNeeded(content: content) }
            )
            store.createVersionBackupIfNeeded()
            return .success(Ready(container: container, store: store))
        } catch {
            return .failure(StartupFailure(message: error.localizedDescription))
        }
    }

    /// 单元测试跑在 App 宿主进程里，必须用内存库与临时目录，避免写坏真实数据。
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

    private static func makeForTests() -> Result<Ready, StartupFailure> {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: RunRecord.self, configurations: configuration)
            let content = try ContentStore.load()
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("SheepChaseTests-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let store = RunStore(
                repository: RunRepository(context: container.mainContext),
                content: content,
                appVersion: AppVersion.short,
                backupDirectory: directory,
                templateRepository: AdventureTemplateRepository(
                    fileURL: directory.appendingPathComponent(LocalDataLayout.templateFileName)
                )
            )
            return .success(Ready(container: container, store: store))
        } catch {
            return .failure(StartupFailure(message: error.localizedDescription))
        }
    }

    private static func makeContainer(baseDirectory: URL) throws -> ModelContainer {
        let url = try LocalDataLayout.storeURL(in: baseDirectory)
        return try ModelContainer(for: RunRecord.self, configurations: ModelConfiguration(url: url))
    }

    private static func baseDirectory() throws -> URL {
        guard let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw StartupFailure(message: "找不到 Application Support 目录。")
        }
        return directory
    }
}

struct StartupFailure: Error {
    let message: String
}
