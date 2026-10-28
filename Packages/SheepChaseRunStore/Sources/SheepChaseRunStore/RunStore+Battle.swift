import SheepChaseBattleEngine
import SheepChaseCore
import SheepChaseExport
import SheepChasePersistence
import Foundation
import Observation
import SwiftData

@MainActor
extension RunStore {
    // MARK: - Battle

    public func battleState(for run: RunRecord) -> BattleState? {
        run.battle
    }

    public func openBattleSetup(for run: RunRecord) {
        if run.battle == nil {
            run.battle = BattleState()
        }
        run.mode = .battle
        selectedTab = .battle
        commit(run)
    }

    public func toggleBattlePlayer(_ member: PartyMember, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.togglePlayer(member.id, battle: &battle)
        run.battle = battle
        commit(run)
    }

    public func addBattleMonster(_ monster: ContentPack.Monster, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        let count = battle.monsters.filter { $0.baseID == monster.id }.count + 1
        let name: String
        switch monster.id {
        case "wolf-guard": name = "狼 \(count)"
        case "brown-bear": name = count == 1 ? "棕熊" : "棕熊 \(count)"
        case "bed-dragon-wyrmling": name = count == 1 ? "床龙雏龙" : "床龙雏龙 \(count)"
        default: name = count == 1 ? monster.name : "\(monster.name) \(count)"
        }
        battle.monsters.append(BattleMonster(baseID: monster.id, name: name))
        run.battle = battle
        commit(run)
    }

    public func removeBattleMonster(_ monsterID: UUID, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        battle.monsters.removeAll { $0.id == monsterID }
        run.battle = battle
        commit(run)
    }

    public func clearBattleDraft(in run: RunRecord) {
        run.battle = BattleState()
        commit(run)
    }

    public func goToInitiative(in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.goToInitiative(
            battle: &battle,
            monsters: content.monsters,
            d20Roll: { self.d20() }
        )
        run.battle = battle
        commit(run)
    }

    public func backToSelect(in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.backToSelect(battle: &battle)
        run.battle = battle
        commit(run)
    }

    public func setPlayerInitiative(_ text: String, memberID: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.setPlayerInitiative(text, memberID: memberID, battle: &battle)
        run.battle = battle
        commit(run)
    }

    public func battleReady(_ run: RunRecord) -> Bool {
        guard let battle = run.battle else { return false }
        return BattleEngine.battleReady(battle)
    }

    public func suggestedEncounter(for run: RunRecord) -> String {
        guard let battle = run.battle else { return "先选择参战玩家" }
        return BattleEngine.suggestedEncounter(battle, players: run.party)
    }

    public func startBattle(in run: RunRecord) {
        guard var battle = run.battle else { return }
        guard BattleEngine.start(
            battle: &battle,
            players: run.party,
            monsters: content.monsters
        ) else { return }

        run.battle = battle
        run.mode = .battle
        selectedTab = .battle
        commit(run)
        createCheckpoint("进入战斗", in: run)
        notify("先攻已记录，进入第 1 轮")
    }

    public func nextTurn(in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.nextTurn(battle: &battle)
        run.battle = battle
        commit(run)
    }

    public func setTemporaryHP(_ value: Int, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.setTemporaryHP(value, forID: id, battle: &battle)
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    public func adjustHP(_ delta: Int, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.adjustHP(delta, battle: &battle)
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    public func adjustHP(forID id: UUID, delta: Int, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.adjustHP(forID: id, delta: delta, battle: &battle)
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    public func toggleCondition(_ condition: String, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.toggleCondition(condition, battle: &battle)
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    public func setConcentration(_ text: String, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.setConcentration(text, forID: id, battle: &battle)
        run.battle = battle
        commit(run)
    }

    public func rollDice(sides: Int, count: Int = 1, modifier: Int = 0, in run: RunRecord) -> Int {
        guard var battle = run.battle else { return 0 }
        let total = BattleEngine.rollDice(
            sides: sides,
            count: count,
            modifier: modifier,
            battle: &battle
        )
        run.battle = battle
        commit(run)
        return total
    }

    public func undoBattle(in run: RunRecord) {
        guard var battle = run.battle else { return }
        guard BattleEngine.undo(battle: &battle) else { return }
        run.battle = battle
        syncParty(run)
        commit(run)
        notify("已撤销上一步")
    }

    public func selectCombatant(_ id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.selectCombatant(id, battle: &battle)
        run.battle = battle
        commit(run)
    }

    public func endBattle(in run: RunRecord) {
        syncParty(run)
        run.lastBattle = run.battle
        run.battle = nil
        run.mode = .scene
        selectedTab = .party
        commit(run)
        createCheckpoint("战斗结束", in: run)
        notify("战斗结束，HP 与状态已同步")
    }

    public func activeCombatant(in run: RunRecord) -> BattleCombatant? {
        guard let battle = run.battle else { return nil }
        return BattleEngine.activeCombatant(battle)
    }
}
