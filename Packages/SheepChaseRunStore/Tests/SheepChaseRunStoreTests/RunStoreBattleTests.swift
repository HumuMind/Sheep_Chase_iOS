import XCTest
import SheepChaseCore
@testable import SheepChaseRunStore

final class RunStoreBattleTests: RunStoreTestCase {
    @MainActor
    func testFinethirSheepAllyStats() throws {
        let store = try makeStore()
        store.createRun(name: "盟友团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        store.openBattleSetup(for: run)
        store.addBattleAlly(in: run)
        let ally = try XCTUnwrap(run.battle?.allies?.first)
        XCTAssertEqual(ally.name, "范席尔（绵羊）")
        XCTAssertEqual(ally.ac, 10)
        XCTAssertEqual(ally.hp, 3)
        XCTAssertEqual(ally.intelligence, 17)
        XCTAssertEqual(ally.wisdom, 12)
        XCTAssertEqual(ally.speed, 40)

        store.addBattleAlly(in: run)
        XCTAssertEqual(run.battle?.allies?.count, 1)
    }

    @MainActor
    func testPrepareEncounterUsesAdjustmentAndRecordsEncounterID() throws {
        let store = try makeStore()
        store.createRun(name: "遭遇团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        store.setEncounterAdjustment(
            encounterID: "guz-ambush",
            combatants: [RunEncounterCombatant(monsterID: "guz", count: 1)],
            note: "只留古兹",
            in: run
        )
        store.prepareEncounter("guz-ambush", in: run)

        XCTAssertEqual(run.battle?.monsters.count, 1)
        XCTAssertEqual(run.battle?.encounterID, "guz-ambush")
    }

    @MainActor
    func testMidBattleJoinsAndInitiativeEdit() throws {
        let content = try contentPack
        let store = try makeStore()
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
        let wolf = try XCTUnwrap(content.monsters.first { $0.id == "wolf-guard" })

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
