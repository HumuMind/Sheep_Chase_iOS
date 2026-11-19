import Foundation
import SwiftData
import XCTest
import SheepChaseCore
import SheepChasePersistence
@testable import SheepChaseRunStore

/// 共用测试脚手架：加载真实内容包，并建一个内存 SwiftData 的 RunStore。
@MainActor
class RunStoreTestCase: XCTestCase {
    /// 测试期间保持容器存活，避免上下文失效。
    private var containers: [ModelContainer] = []

    var contentPack: ContentPack {
        get throws {
            var root = URL(fileURLWithPath: #filePath)
            for _ in 0..<5 { root.deleteLastPathComponent() }
            let url = root.appendingPathComponent("SheepChase/Resources/ContentPack.json")
            return try JSONDecoder().decode(ContentPack.self, from: Data(contentsOf: url))
        }
    }

    func makeStore(seed: @escaping () -> [RunRecord] = { [] }) throws -> RunStore {
        let templateURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("template-test-\(UUID().uuidString).json")
        return try makeStore(templateFileURL: templateURL, seed: seed)
    }

    func makeStore(templateFileURL: URL, seed: @escaping () -> [RunRecord] = { [] }) throws -> RunStore {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: configuration)
        containers.append(container)
        return RunStore(
            repository: RunRepository(context: container.mainContext),
            content: try contentPack,
            appVersion: "test",
            backupDirectory: FileManager.default.temporaryDirectory,
            templateRepository: AdventureTemplateRepository(fileURL: templateFileURL),
            seed: seed
        )
    }
}
