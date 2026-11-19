@testable import SheepChaseRunStore
import Foundation
import XCTest
import SheepChaseCore
import SheepChasePersistence

final class RunStorePersistenceErrorTests: RunStoreTestCase {
    private func makeTemplate() -> AdventureTemplate {
        AdventureTemplate(
            name: "测试模组",
            summary: "摘要",
            baseModuleID: "wild-sheep-chase",
            baseModuleTitle: "荒野逐羊",
            baseContentVersion: "0.7.1",
            patch: AdventureTemplatePatch(annotations: [
                DMAnnotation(targetKind: .scene, targetID: "scene-1", text: "改台词")
            ])
        )
    }

    @MainActor
    func testCorruptTemplateFileSurfacesPersistenceError() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("broken-template-\(UUID().uuidString).json")
        try Data("{ 不是模组 }".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let store = try makeStore(templateFileURL: url)

        XCTAssertTrue(store.templates.isEmpty)
        let message = try XCTUnwrap(store.persistenceError)
        XCTAssertTrue(message.contains("读取我的模组失败"), message)
    }

    @MainActor
    func testDeleteTemplateRollsBackWhenSaveFails() throws {
        let store = try makeStore(templateFileURL: URL(fileURLWithPath: "/dev/null/templates.json"))
        store.templates = [makeTemplate()]
        let template = try XCTUnwrap(store.templates.first)

        XCTAssertThrowsError(try store.deleteTemplate(template))

        XCTAssertEqual(store.templates.count, 1)
        XCTAssertEqual(store.templates.first?.name, "测试模组")
        XCTAssertNil(store.toast)
    }

    @MainActor
    func testRenameTemplateRollsBackWhenSaveFails() throws {
        let store = try makeStore(templateFileURL: URL(fileURLWithPath: "/dev/null/templates.json"))
        store.templates = [makeTemplate()]
        let template = try XCTUnwrap(store.templates.first)

        XCTAssertThrowsError(try store.renameTemplate(template, to: "新名字"))

        XCTAssertEqual(store.templates.first?.name, "测试模组")
        XCTAssertNil(store.toast)
    }
}
