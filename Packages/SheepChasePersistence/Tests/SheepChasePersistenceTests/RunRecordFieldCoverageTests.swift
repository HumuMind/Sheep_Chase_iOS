@testable import SheepChasePersistence
import Foundation
import SheepChaseCore
import SwiftData
import XCTest

final class RunRecordFieldCoverageTests: XCTestCase {
    private func makeContainer(at url: URL) throws -> ModelContainer {
        try ModelContainer(for: RunRecord.self, configurations: ModelConfiguration(url: url))
    }

    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("run-\(UUID().uuidString).store")
    }

    @MainActor
    func testAllPersistedFieldsSurviveDiskRoundTrip() throws {
        let storeURL = temporaryStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let combatant = BattleCombatant(
            id: UUID(),
            name: "阿岚",
            kind: .player,
            baseID: nil,
            ac: 18,
            hp: 31,
            maxHP: 44,
            initiative: 17,
            tempHP: 5,
            conditions: ["中毒"],
            concentration: "祝福术",
            notes: "前排"
        )
        let battle = BattleState(
            phase: .active,
            encounterID: "guz-ambush",
            selectedPlayerIDs: [combatant.id],
            monsters: [BattleMonster(baseID: "wolf-guard", name: "狼 1", initiative: 12)],
            allies: [BattleAlly(baseID: "finethir-sheep", name: "菲尼斯", ac: 10, hp: 3, maxHP: 3)],
            playerInitiatives: [combatant.id.uuidString: 17],
            combatants: [combatant],
            round: 3,
            activeID: combatant.id,
            log: ["第 3 轮 · 阿岚"]
        )
        let snapshot = RunStateSnapshot(
            name: "存档点",
            contentVersion: "9.9.9",
            sceneID: "scene-2",
            beatID: "beat-2",
            mode: .battle,
            party: [],
            flags: [:],
            notes: [],
            safety: SafetyState()
        )

        do {
            let container = try makeContainer(at: storeURL)
            let repository = RunRepository(context: container.mainContext)
            let run = RunRecord(name: "全字段团", sceneID: "scene-3", beatID: "beat-3", contentVersion: "9.9.9")
            run.mode = .map
            run.party = [
                PartyMember(
                    name: "阿岚",
                    role: "战士",
                    level: 5,
                    ac: 18,
                    maxHP: 44,
                    hp: 31,
                    initMod: 2,
                    passivePerception: 13,
                    tempHP: 5,
                    conditions: ["中毒"]
                )
            ]
            run.flags = ["sheep-freed": true]
            run.stickyNotes = [StickyNote(text: "记住狼群", color: .pink)]
            run.battle = battle
            run.lastBattle = battle
            run.safety = SafetyState(lines: "不描写血腥", veils: "无", pauseSignal: "举杯", notes: "备注", restLog: ["休息 1"])
            run.sessions = [RunSession(note: "第一场")]
            run.checkpoints = [RunCheckpoint(label: "进城堡前", state: snapshot)]
            run.sceneNotes = ["scene-3": "先讲风声"]
            run.prepChecks = ["prep-1"]
            run.pinnedReferenceIDs = ["rule-1"]
            run.annotations = [DMAnnotation(targetKind: .scene, targetID: "scene-3", mode: .replace, text: "改台词")]
            run.customBeats = [RunCustomBeat(sceneID: "scene-3", title: "加一段追击", text: "细节")]
            run.customMapPins = [RunCustomMapPin(mapID: "map-1", x: 0.4, y: 0.6, label: "羊圈")]
            run.customNPCs = [RunCustomNPC(name: "菲尼斯", role: "委托人", description: "羊", keyCharacteristics: ["紧张"])]
            run.customMonsters = [
                RunCustomMonster(name: "床龙犬", ac: 13, hp: 22, initiativeModifier: 2, actionText: "咬")
            ]
            run.encounterAdjustments = [
                RunEncounterAdjustment(
                    encounterID: "guz-ambush",
                    combatants: [RunEncounterCombatant(monsterID: "wolf-guard", count: 2)],
                    note: "削弱"
                )
            ]
            run.monsterOverrides = [RunMonsterOverride(monsterID: "wolf-guard", ac: 13, hp: 20, note: "削弱")]
            run.diceHistory = [
                DiceRoll(
                    command: "1d20+3",
                    mode: .normal,
                    checks: [DiceCheck(rawRolls: [11], kept: 11, total: 14)],
                    total: 14,
                    subject: "阿岚"
                )
            ]
            run.sourceTemplateID = UUID()
            run.sourceTemplateName = "我的模组"
            run.sourceTemplateBaseVersion = "9.9.9"
            repository.insert(run)
            try repository.save()
        }

        let container = try makeContainer(at: storeURL)
        let repository = RunRepository(context: container.mainContext)
        let fetched = try XCTUnwrap(try repository.fetchAll().first)

        XCTAssertEqual(fetched.name, "全字段团")
        XCTAssertEqual(fetched.mode, .map)
        XCTAssertEqual(fetched.party.first?.conditions, ["中毒"])
        XCTAssertEqual(fetched.flags["sheep-freed"], true)
        XCTAssertEqual(fetched.stickyNotes.first?.color, .pink)
        XCTAssertEqual(fetched.battle?.round, 3)
        XCTAssertEqual(fetched.battle?.encounterID, "guz-ambush")
        XCTAssertEqual(fetched.battle?.combatants.first?.notes, "前排")
        XCTAssertEqual(fetched.battle?.allies?.first?.name, "菲尼斯")
        XCTAssertEqual(fetched.lastBattle?.activeID, fetched.battle?.activeID)
        XCTAssertEqual(fetched.safety.pauseSignal, "举杯")
        XCTAssertEqual(fetched.sessions.first?.note, "第一场")
        XCTAssertEqual(fetched.checkpoints.first?.label, "进城堡前")
        XCTAssertEqual(fetched.sceneNotes["scene-3"], "先讲风声")
        XCTAssertEqual(fetched.prepChecks, ["prep-1"])
        XCTAssertEqual(fetched.pinnedReferenceIDs, ["rule-1"])
        XCTAssertEqual(fetched.annotations.first?.text, "改台词")
        XCTAssertEqual(fetched.customBeats.first?.title, "加一段追击")
        XCTAssertEqual(fetched.customMapPins.first?.label, "羊圈")
        XCTAssertEqual(fetched.customNPCs.first?.name, "菲尼斯")
        XCTAssertEqual(fetched.customMonsters.first?.name, "床龙犬")
        XCTAssertEqual(fetched.encounterAdjustments.first?.combatants.first?.count, 2)
        XCTAssertEqual(fetched.monsterOverrides.first?.hp, 20)
        XCTAssertEqual(fetched.diceHistory.first?.total, 14)
        XCTAssertEqual(fetched.sourceTemplateName, "我的模组")
        XCTAssertTrue(fetched.damagedSections.isEmpty)
    }

    @MainActor
    func testCorruptedFieldDecodesToDefaultAndIsReported() throws {
        let storeURL = temporaryStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL) }

        do {
            let container = try makeContainer(at: storeURL)
            let repository = RunRepository(context: container.mainContext)
            let run = RunRecord(name: "损坏团")
            run.stickyNotes = [StickyNote(text: "正常便签")]
            run.notesData = Data("不是 JSON".utf8)
            repository.insert(run)
            try repository.save()
        }

        let container = try makeContainer(at: storeURL)
        let repository = RunRepository(context: container.mainContext)
        let fetched = try XCTUnwrap(try repository.fetchAll().first)

        XCTAssertEqual(fetched.stickyNotes, [])
        XCTAssertEqual(fetched.damagedSections, ["便签"])
    }
}
