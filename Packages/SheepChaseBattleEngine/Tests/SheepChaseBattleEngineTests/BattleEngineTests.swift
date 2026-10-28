import Foundation
import XCTest
import SheepChaseCore
@testable import SheepChaseBattleEngine

final class BattleEngineTests: XCTestCase {
    private func player(name: String, initiative: Int) -> PartyMember {
        PartyMember(name: name, role: "战士", level: 4, ac: 16, maxHP: 30, hp: 30, initMod: 1, passivePerception: 10, tempHP: 0)
    }

    private func battle(players: [PartyMember]) -> BattleState {
        var state = BattleState(phase: .select)
        for member in players {
            state.selectedPlayerIDs.append(member.id)
            state.playerInitiatives[member.id.uuidString] = 10
        }
        state.phase = .initiative
        return state
    }

    func testStartOrdersByInitiative() {
        let a = player(name: "阿岚", initiative: 10)
        let b = player(name: "米娅", initiative: 10)
        var state = battle(players: [a, b])
        state.playerInitiatives[a.id.uuidString] = 18
        state.playerInitiatives[b.id.uuidString] = 12

        XCTAssertTrue(BattleEngine.battleReady(state))
        XCTAssertTrue(BattleEngine.start(battle: &state, players: [a, b], monsters: []))
        XCTAssertEqual(state.phase, .active)
        XCTAssertEqual(state.combatants.map(\.name), ["阿岚", "米娅"])
        XCTAssertEqual(state.activeID, a.id)
        XCTAssertEqual(state.round, 1)
    }

    func testTempHPAbsorbsDamageAndConcentrationUndo() {
        let a = player(name: "阿岚", initiative: 10)
        var state = battle(players: [a])
        XCTAssertTrue(BattleEngine.start(battle: &state, players: [a], monsters: []))
        let id = try! XCTUnwrap(state.activeID)

        BattleEngine.setTemporaryHP(5, forID: id, battle: &state)
        BattleEngine.setConcentration("加速术", forID: id, battle: &state)
        BattleEngine.adjustHP(forID: id, delta: -8, battle: &state)

        let combatant = state.combatants.first { $0.id == id }
        XCTAssertEqual(combatant?.tempHP, 0)
        XCTAssertEqual(combatant?.hp, 27)
        XCTAssertTrue(state.log.contains { $0.contains("DC 10") })

        XCTAssertTrue(BattleEngine.undo(battle: &state))
        XCTAssertEqual(state.combatants.first { $0.id == id }?.hp, 30)
        XCTAssertEqual(state.combatants.first { $0.id == id }?.tempHP, 5)
    }

    func testNextTurnAdvancesRound() {
        let a = player(name: "阿岚", initiative: 10)
        let b = player(name: "米娅", initiative: 10)
        var state = battle(players: [a, b])
        XCTAssertTrue(BattleEngine.start(battle: &state, players: [a, b], monsters: []))
        BattleEngine.nextTurn(battle: &state)
        XCTAssertEqual(state.round, 1)
        BattleEngine.nextTurn(battle: &state)
        XCTAssertEqual(state.round, 2)
    }

    func testDeterministicDice() {
        var state = BattleState()
        let total = BattleEngine.rollDice(
            sides: 6,
            count: 2,
            modifier: 3,
            battle: &state,
            dieRoll: { _ in 4 }
        )
        XCTAssertEqual(total, 11)
        XCTAssertTrue(state.log.first?.contains("2d6+3 = 11") == true)
    }
}
