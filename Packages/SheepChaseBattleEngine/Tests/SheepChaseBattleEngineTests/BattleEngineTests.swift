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

    func testSetHPAndCombatantNotes() {
        let player = player(name: "阿岚", initiative: 10)
        var state = battle(players: [player])
        XCTAssertTrue(BattleEngine.start(battle: &state, players: [player], monsters: []))
        guard let id = state.combatants.first?.id else { return XCTFail("missing combatant") }
        BattleEngine.setHP(7, forID: id, battle: &state)
        XCTAssertEqual(state.combatants.first?.hp, 7)
        let logCount = state.log.count
        BattleEngine.setHP(7, forID: id, battle: &state)
        XCTAssertEqual(state.log.count, logCount)
        BattleEngine.setNotes("准备动作：格挡", forID: id, battle: &state)
        XCTAssertEqual(state.combatants.first?.notes, "准备动作：格挡")
        BattleEngine.setHP(0, forID: id, battle: &state)
        XCTAssertEqual(state.combatants.first?.hp, 0)
        XCTAssertTrue(state.combatants.first?.conditions.contains("倒地") == true)
    }

    func testNPCAllyBecomesBattleCombatant() {
        let player = player(name: "阿岚", initiative: 10)
        var state = battle(players: [player])
        state.allies = [
            BattleAlly(
                baseID: "finethir-sheep",
                name: "范席尔（绵羊）",
                subtitle: "NPC 盟友",
                ac: 10,
                hp: 3,
                maxHP: 3,
                initiative: 12
            )
        ]
        XCTAssertTrue(BattleEngine.start(battle: &state, players: [player], monsters: [], allies: state.allies ?? []))
        let ally = state.combatants.first { $0.kind == .npc }
        XCTAssertEqual(ally?.name, "范席尔（绵羊）")
        XCTAssertEqual(ally?.baseID, "finethir-sheep")
        XCTAssertEqual(ally?.ac, 10)
        XCTAssertEqual(ally?.hp, 3)
    }

    func testMonsterCombatantKeepsBaseID() {
        let player = player(name: "阿岚", initiative: 10)
        var state = battle(players: [player])
        let monster = ContentPack.Monster.custom(
            id: "guz",
            name: "古兹",
            size: "中型",
            type: "类人生物（半兽人）",
            alignment: "混乱中立",
            ac: .init(value: 14),
            hp: .init(average: 67, formula: "9d8+27"),
            speed: .init(walk: 30),
            abilities: .init(str: 16, dex: 12, con: 17, int: 8, wis: 11, cha: 8),
            challenge: .init(rating: 2, xp: 450),
            actions: [.init(name: "回旋巨剑", text: "近战武器攻击。")]
        )
        state.monsters = [BattleMonster(baseID: "guz", name: "古兹", initiative: 8)]
        XCTAssertTrue(BattleEngine.start(battle: &state, players: [player], monsters: [monster]))
        XCTAssertEqual(state.combatants.first { $0.kind == .monster }?.baseID, "guz")
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
