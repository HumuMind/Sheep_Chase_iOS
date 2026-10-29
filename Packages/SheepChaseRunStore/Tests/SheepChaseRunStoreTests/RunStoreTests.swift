import Foundation
import SwiftData
import XCTest
import SheepChaseCore
import SheepChasePersistence
@testable import SheepChaseRunStore

final class RunStoreTests: XCTestCase {
    private var content: ContentPack {
        get throws {
            var root = URL(fileURLWithPath: #filePath)
            for _ in 0..<5 { root.deleteLastPathComponent() }
            let url = root.appendingPathComponent("SheepChase/Resources/ContentPack.json")
            return try JSONDecoder().decode(ContentPack.self, from: Data(contentsOf: url))
        }
    }

    @MainActor
    func testStoreSeedsAndCreatesRuns() throws {
        let content = try content
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: config)
        let repository = RunRepository(context: container.mainContext)
        let seedRun = RunRecord(name: "种子团", contentVersion: content.manifest.version)
        let templateURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("template-test-\(UUID().uuidString).json")
        let templateRepository = AdventureTemplateRepository(fileURL: templateURL)
        let store = RunStore(
            repository: repository,
            content: content,
            appVersion: "test",
            backupDirectory: FileManager.default.temporaryDirectory,
            templateRepository: templateRepository,
            seed: { [seedRun] }
        )

        XCTAssertEqual(store.runs.count, 1)
        XCTAssertEqual(store.runs.first?.name, "种子团")

        store.createRun(name: "新团")
        XCTAssertEqual(store.runs.count, 2)
        guard let run = store.selectedRun else { return XCTFail("missing run") }
        XCTAssertEqual(run.name, "新团")
        XCTAssertEqual(store.scenes.count, 4)

        store.selectScene(store.scenes[2], in: run)
        XCTAssertEqual(run.sceneID, "scene-3")
        store.addNote(to: run)
        XCTAssertEqual(run.stickyNotes.count, 1)
        store.setArchived(true, in: run)
        XCTAssertFalse(store.orderedRuns.contains { $0.id == run.id })

        store.togglePinnedReference("npc:finethir-shinebright", in: run)
        XCTAssertTrue(store.isPinnedReference("npc:finethir-shinebright", in: run))
        store.togglePinnedReference("npc:finethir-shinebright", in: run)
        XCTAssertFalse(store.isPinnedReference("npc:finethir-shinebright", in: run))

        store.setAnnotation(kind: .scene, targetID: "scene-3", mode: .replace, text: "我把树屋改成了夜间场景。", in: run)
        XCTAssertEqual(store.annotation(kind: .scene, targetID: "scene-3", in: run)?.text, "我把树屋改成了夜间场景。")
        XCTAssertEqual(store.annotation(kind: .scene, targetID: "scene-3", in: run)?.mode, .replace)
        XCTAssertEqual(run.stateSnapshot.annotations?.first?.text, "我把树屋改成了夜间场景。")
        store.removeAnnotation(kind: .scene, targetID: "scene-3", in: run)
        XCTAssertNil(store.annotation(kind: .scene, targetID: "scene-3", in: run))

        store.addCustomBeat(sceneID: "scene-3", title: "自定义密道", type: "event", text: "队伍发现树屋下的密道。", readAloud: nil, in: run)
        XCTAssertEqual(store.customBeats(for: "scene-3", in: run).first?.title, "自定义密道")
        if let custom = store.customBeats(for: "scene-3", in: run).first {
            store.selectBeatID(custom.id.uuidString, in: run)
            XCTAssertEqual(run.beatID, custom.id.uuidString)
            store.deleteCustomBeat(custom.id, in: run)
        }
        XCTAssertTrue(store.customBeats(for: "scene-3", in: run).isEmpty)

        store.addCustomNPC(name: "自定义线人", role: "情报贩子", description: "知道树屋密道。", keyCharacteristics: ["谨慎"], in: run)
        let customNPC = store.customNPCs(in: run).first
        XCTAssertEqual(customNPC?.name, "自定义线人")
        if let customNPC {
            XCTAssertEqual(store.npc(id: "custom-npc-\(customNPC.id.uuidString)", in: run)?.name, "自定义线人")
        }

        store.addCustomMapPin(mapID: "treehouse", x: 0.4, y: 0.6, label: "密道", note: "通往厨房", in: run)
        XCTAssertEqual(store.customMapPins(for: "treehouse", in: run).first?.label, "密道")

        store.addCustomMonster(name: "守门魔像", size: "大型", type: "构装体", alignment: "无阵营", ac: 17, hp: 60, initiativeModifier: -1, actionText: "挥拳攻击。", in: run)
        XCTAssertTrue(store.orderedBattleMonsters(in: run).contains { $0.name == "守门魔像" })
        if let customMonster = store.customMonsters(in: run).first {
            XCTAssertEqual(store.monster(id: "custom-monster-\(customMonster.id.uuidString)", in: run)?.name, "守门魔像")
        }

        store.setMonsterOverride(monsterID: "guz", ac: 18, hp: 80, initiativeModifier: 4, note: "强化版", in: run)
        XCTAssertEqual(store.monsterForBattle(id: "guz", in: run)?.ac.value, 18)
        XCTAssertEqual(store.monsterForBattle(id: "guz", in: run)?.hp.average, 80)
        XCTAssertEqual(store.monsterForBattle(id: "guz", in: run)?.initiativeModifier, 4)

        store.setEncounterAdjustment(
            encounterID: "guz-ambush",
            combatants: [RunEncounterCombatant(monsterID: "guz", count: 1)],
            note: "只留古兹",
            in: run
        )
        store.prepareEncounter("guz-ambush", in: run)
        XCTAssertEqual(run.battle?.monsters.count, 1)

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

        let reloaded = AdventureTemplateRepository(fileURL: templateURL).load()
        XCTAssertEqual(reloaded.first?.name, "强化古兹")
    }
}
