import XCTest
import SheepChaseCore
import SheepChasePersistence
@testable import SheepChaseRunStore

final class RunStoreTemplateTests: RunStoreTestCase {
    /// 建一个有改动可保存的开团。
    @MainActor
    private func makeCustomizedRun(with store: RunStore) throws -> RunRecord {
        store.createRun(name: "模板源团")
        guard let run = store.selectedRun else { throw XCTSkip("missing run") }
        store.addCustomNPC(
            name: "自定义线人",
            role: "情报贩子",
            description: "知道树屋密道。",
            keyCharacteristics: ["谨慎"],
            in: run
        )
        store.addCustomMonster(
            name: "守门魔像",
            size: "大型",
            type: "构装体",
            alignment: "无阵营",
            ac: 17,
            hp: 60,
            initiativeModifier: -1,
            actionText: "挥拳攻击。",
            in: run
        )
        store.addCustomMapPin(mapID: "treehouse", x: 0.4, y: 0.6, label: "密道", note: "通往厨房", in: run)
        store.setMonsterOverride(monsterID: "guz", ac: 18, hp: 80, initiativeModifier: 4, note: "强化版", in: run)
        return run
    }

    @MainActor
    func testSavingEmptyRunThrows() throws {
        let store = try makeStore()
        store.createRun(name: "空白团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        XCTAssertThrowsError(try store.saveRunAsTemplate(from: run, name: "空模组", summary: ""))
        XCTAssertTrue(store.templates.isEmpty)
    }

    @MainActor
    func testSaveCreateOverwriteAndImportTemplate() throws {
        let content = try contentPack
        let store = try makeStore()
        let run = try makeCustomizedRun(with: store)

        let template = try store.saveRunAsTemplate(from: run, name: "强化古兹", summary: "测试模组")
        XCTAssertEqual(store.templates.count, 1)
        XCTAssertEqual(template.patch.customNPCs.count, 1)
        XCTAssertEqual(template.patch.customMonsters.count, 1)
        XCTAssertEqual(template.patch.customMapPins.count, 1)
        XCTAssertEqual(template.patch.monsterOverrides.count, 1)

        store.createRun(name: "模板团", from: template)
        guard let templateRun = store.selectedRun else { return XCTFail("missing template run") }
        XCTAssertEqual(templateRun.sourceTemplateName, "强化古兹")
        XCTAssertEqual(templateRun.customNPCs.count, 1)
        XCTAssertEqual(templateRun.customMonsters.count, 1)
        XCTAssertEqual(templateRun.monsterOverrides.first?.ac, 18)
        XCTAssertTrue(templateRun.party.isEmpty)
        XCTAssertTrue(templateRun.stickyNotes.isEmpty)

        let reloaded = try AdventureTemplateRepository(fileURL: store.templateRepository.fileURL).load()
        XCTAssertEqual(reloaded.first?.name, "强化古兹")

        try store.overwriteTemplate(template, from: run, name: "强化古兹 2", summary: "覆盖测试")
        XCTAssertEqual(store.templates.first?.name, "强化古兹 2")
        XCTAssertEqual(store.templates.first?.summary, "覆盖测试")

        let imported = AdventureTemplate(
            name: "导入模组",
            baseModuleID: content.manifest.id,
            baseModuleTitle: content.manifest.title,
            baseContentVersion: content.manifest.version,
            patch: template.patch
        )
        let importedTemplate = try store.importTemplate(imported)
        XCTAssertNotEqual(importedTemplate.id, imported.id)
        XCTAssertTrue(store.templates.contains { $0.name == "导入模组" })
    }
}
