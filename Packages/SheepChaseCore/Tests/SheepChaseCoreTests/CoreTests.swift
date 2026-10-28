import XCTest
@testable import SheepChaseCore

final class CoreTests: XCTestCase {
    func testPartyMemberRoundTrip() throws {
        let member = PartyMember(
            name: "阿岚",
            role: "战士",
            level: 4,
            ac: 18,
            maxHP: 44,
            hp: 31,
            initMod: 1,
            passivePerception: 12,
            tempHP: 5,
            conditions: ["受擒"]
        )
        let data = try JSONEncoder().encode(member)
        let decoded = try JSONDecoder().decode(PartyMember.self, from: data)
        XCTAssertEqual(decoded.name, "阿岚")
        XCTAssertEqual(decoded.tempHP, 5)
        XCTAssertEqual(decoded.conditions, ["受擒"])
    }

    func testBattleStateKeepsTempHPAndConcentration() throws {
        let id = UUID()
        let combatant = BattleCombatant(
            id: id,
            name: "诺克",
            kind: .monster,
            baseID: "noke",
            ac: 12,
            hp: 35,
            maxHP: 35,
            initiative: 14,
            tempHP: 4,
            conditions: ["恐慌"],
            concentration: "加速术"
        )
        let state = BattleState(
            phase: .active,
            selectedPlayerIDs: [],
            monsters: [],
            combatants: [combatant],
            round: 2,
            activeID: id,
            log: ["第 2 轮"]
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(BattleState.self, from: data)
        XCTAssertEqual(decoded.combatants.first?.tempHP, 4)
        XCTAssertEqual(decoded.combatants.first?.concentration, "加速术")
        XCTAssertEqual(decoded.totalParticipants, 0)
    }

    func testRunSnapshotSessionsAndSceneNotes() throws {
        let snapshot = RunStateSnapshot(
            name: "测试团",
            contentVersion: "0.3.0",
            sceneID: "scene-3",
            beatID: "guards-in-the-open",
            mode: .scene,
            party: [],
            flags: ["noke-alerted": true],
            notes: [StickyNote(text: "便签")],
            safety: SafetyState(restLog: ["中场休息"]),
            sessions: [RunSession(note: "第一次")],
            sceneNotes: ["scene-3": "场景备注"],
            prepChecks: ["scene:scene-3"]
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(RunStateSnapshot.self, from: data)
        XCTAssertEqual(decoded.sessions?.first?.note, "第一次")
        XCTAssertEqual(decoded.sceneNotes?["scene-3"], "场景备注")
        XCTAssertEqual(decoded.safety.restLog, ["中场休息"])
    }
}
