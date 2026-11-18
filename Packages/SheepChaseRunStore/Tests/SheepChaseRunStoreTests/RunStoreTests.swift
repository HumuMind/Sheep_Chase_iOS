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

        let first = store.addAnnotation(kind: .beat, targetID: "beat-1", mode: .append, text: "第一条", in: run)
        let second = store.addAnnotation(kind: .beat, targetID: "beat-1", mode: .replace, text: "第二条", in: run)
        XCTAssertEqual(store.annotations(kind: .beat, targetID: "beat-1", in: run).count, 2)
        if let first {
            store.updateAnnotation(id: first.id, mode: .replace, text: "第一条改", in: run)
            XCTAssertEqual(store.annotations(kind: .beat, targetID: "beat-1", in: run).first?.text, "第一条改")
        }
        if let second {
            store.removeAnnotation(id: second.id, in: run)
        }
        XCTAssertEqual(store.annotations(kind: .beat, targetID: "beat-1", in: run).count, 1)

        store.addCustomBeat(sceneID: "scene-3", title: "自定义密道", type: "event", text: "队伍发现树屋下的密道。", readAloud: nil, in: run)
        XCTAssertEqual(store.customBeats(for: "scene-3", in: run).first?.title, "自定义密道")
        if let custom = store.customBeats(for: "scene-3", in: run).first {
            store.selectBeatID(custom.id.uuidString, in: run)
            XCTAssertEqual(run.beatID, custom.id.uuidString)
            store.updateCustomBeat(custom.id, title: "密道入口", type: "decision", text: "队伍决定是否进入密道。", readAloud: nil, in: run)
            XCTAssertEqual(store.customBeats(for: "scene-3", in: run).first?.title, "密道入口")
            store.deleteCustomBeat(custom.id, in: run)
        }
        XCTAssertTrue(store.customBeats(for: "scene-3", in: run).isEmpty)

        store.addCustomNPC(name: "自定义线人", role: "情报贩子", description: "知道树屋密道。", keyCharacteristics: ["谨慎"], in: run)
        let customNPC = store.customNPCs(in: run).first
        XCTAssertEqual(customNPC?.name, "自定义线人")
        if let customNPC {
            XCTAssertEqual(store.npc(id: "custom-npc-\(customNPC.id.uuidString)", in: run)?.name, "自定义线人")
        }

        store.openBattleSetup(for: run)
        store.addBattleAlly(in: run)
        XCTAssertEqual(run.battle?.allies?.first?.name, "范席尔（绵羊）")
        XCTAssertEqual(run.battle?.allies?.first?.intelligence, 17)
        XCTAssertEqual(run.battle?.allies?.first?.wisdom, 12)
        XCTAssertEqual(run.battle?.allies?.first?.speed, 40)

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

        let diceExpression = DiceExpression(terms: [DiceTerm(count: 2, sides: 6)], modifier: 3)
        let roll = store.rollDice(diceExpression, command: "2d6+3", subject: "古兹", logToBattle: true, in: run) { _ in 4 }
        XCTAssertEqual(roll.total, 11)
        XCTAssertEqual(store.diceHistory(in: run).first?.command, "2d6+3")
        XCTAssertEqual(store.diceHistory(in: run).first?.subject, "古兹")
        XCTAssertEqual(run.stateSnapshot.diceHistory?.first?.total, 11)
        XCTAssertTrue(run.battle?.log.first?.contains("骰子 · 古兹") == true)
        store.clearDiceHistory(in: run)
        XCTAssertTrue(store.diceHistory(in: run).isEmpty)
    }

    @MainActor
    func testMidBattleJoinsAndInitiativeEdit() throws {
        let content = try content
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: config)
        let repository = RunRepository(context: container.mainContext)
        let store = RunStore(
            repository: repository,
            content: content,
            appVersion: "test",
            backupDirectory: FileManager.default.temporaryDirectory
        )

        store.createRun(name: "中途加入测试")
        guard let run = store.selectedRun else { return XCTFail("missing run") }
        for index in 1...4 {
            store.addPlayer(
                to: run,
                name: "玩家\(index)",
                role: "冒险者",
                level: 4,
                ac: 15,
                maxHP: 30,
                initMod: 2,
                passivePerception: 12
            )
        }
        guard let wolf = content.monsters.first(where: { $0.id == "wolf-guard" }) else {
            return XCTFail("missing wolf")
        }

        store.openBattleSetup(for: run)
        let players = run.party
        for member in players.prefix(3) {
            store.toggleBattlePlayer(member, in: run)
        }
        store.addBattleMonster(wolf, in: run)
        store.goToInitiative(in: run)
        for (index, member) in players.prefix(3).enumerated() {
            store.setPlayerInitiative(String(20 - index), memberID: member.id, in: run)
        }
        store.startBattle(in: run)
        XCTAssertEqual(run.battle?.phase, .active)
        XCTAssertEqual(run.battle?.combatants.count, 4)

        let latePlayer = players[3]
        store.joinBattlePlayer(latePlayer, initiative: 25, in: run)
        XCTAssertEqual(run.battle?.combatants.count, 5)
        XCTAssertEqual(run.battle?.combatants.first?.id, latePlayer.id)
        XCTAssertEqual(run.battle?.combatants.first?.initiative, 25)
        XCTAssertTrue(run.battle?.log.first?.contains("加入战斗") == true)

        store.setCombatantInitiative(1, forID: latePlayer.id, in: run)
        XCTAssertEqual(run.battle?.combatants.last?.id, latePlayer.id)
        XCTAssertEqual(run.battle?.combatants.last?.initiative, 1)
        XCTAssertTrue(run.battle?.log.first?.contains("先攻调整") == true)

        store.undoBattle(in: run)
        XCTAssertEqual(run.battle?.combatants.first?.id, latePlayer.id)
        XCTAssertEqual(run.battle?.combatants.first?.initiative, 25)

        let beforeJoin = run.battle?.combatants.count ?? 0
        store.joinBattleMonster(wolf, in: run)
        XCTAssertEqual(run.battle?.combatants.count, beforeJoin + 1)
        XCTAssertEqual(run.battle?.combatants.last?.baseID, wolf.id)
        XCTAssertTrue(run.battle?.log.first?.contains("加入战斗") == true)

        store.undoBattle(in: run)
        XCTAssertEqual(run.battle?.combatants.count, beforeJoin)
    }
}
