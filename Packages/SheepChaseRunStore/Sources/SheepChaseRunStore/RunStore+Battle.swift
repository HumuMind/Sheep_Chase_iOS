import Foundation
import Observation
import SheepChaseBattleEngine
import SheepChaseCore
import SheepChasePersistence
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
        battle.monsters.append(
            BattleMonster(baseID: monster.id, name: battleMonsterName(monster, count: count))
        )
        run.battle = battle
        commit(run)
    }

    public func addBattleAlly(in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        guard !(battle.allies ?? []).contains(where: { $0.baseID == ModuleBattleAllies.finethirSheepID }) else {
            return
        }
        var allies = battle.allies ?? []
        allies.append(ModuleBattleAllies.finethirSheep())
        battle.allies = allies
        run.battle = battle
        commit(run)
    }

    public func removeBattleAlly(_ allyID: UUID, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        battle.allies?.removeAll { $0.id == allyID }
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
            monsters: battleMonsters(in: run),
            allies: battle.allies ?? [],
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

    public func setCombatantInitiative(_ value: Int, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        guard BattleEngine.setInitiative(value, forID: id, battle: &battle) else { return }
        run.battle = battle
        commit(run)
    }

    public func joinBattlePlayer(_ member: PartyMember, initiative: Int, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .active else { return }
        guard !battle.combatants.contains(where: { $0.id == member.id }) else { return }
        let combatant = BattleCombatant(
            id: member.id,
            name: member.name,
            kind: .player,
            ac: member.ac,
            hp: member.hp,
            maxHP: member.maxHP,
            initiative: initiative,
            tempHP: member.tempHP,
            conditions: member.conditions
        )
        guard BattleEngine.appendCombatant(combatant, battle: &battle) else { return }
        run.battle = battle
        syncParty(run)
        guard commit(run) else { return }
        notify("\(member.name) 加入战斗 · 先攻 \(initiative)")
    }

    public func joinBattleMonster(_ monster: ContentPack.Monster, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .active else { return }
        let count = battle.combatants.filter { $0.baseID == monster.id }.count + 1
        let combatant = BattleCombatant(
            id: UUID(),
            name: battleMonsterName(monster, count: count),
            kind: .monster,
            baseID: monster.id,
            ac: monster.ac.value,
            hp: monster.hp.average,
            maxHP: monster.hp.average,
            initiative: d20() + monster.initiativeModifier,
            tempHP: 0
        )
        guard BattleEngine.appendCombatant(combatant, battle: &battle) else { return }
        run.battle = battle
        guard commit(run) else { return }
        notify("\(combatant.name) 加入战斗 · 先攻 \(combatant.initiative)")
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
            monsters: battleMonsters(in: run),
            allies: battle.allies ?? []
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

    public func setHP(_ value: Int, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.setHP(value, forID: id, battle: &battle)
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    public func setCombatantNote(_ text: String, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        BattleEngine.setNotes(text, forID: id, battle: &battle)
        run.battle = battle
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
        guard commit(run) else { return }
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

    private func battleMonsterName(_ monster: ContentPack.Monster, count: Int) -> String {
        switch monster.id {
        case "wolf-guard":
            return "狼 \(count)"
        case "brown-bear":
            return count == 1 ? "棕熊" : "棕熊 \(count)"
        case "bed-dragon-wyrmling":
            return count == 1 ? "床龙雏龙" : "床龙雏龙 \(count)"
        default:
            return count == 1 ? monster.name : "\(monster.name) \(count)"
        }
    }

    // MARK: - Party sync

    /// 把战斗里的 HP、临时 HP 与状态同步回队伍。
    func syncParty(_ run: RunRecord) {
        guard let battle = run.battle else { return }
        var party = run.party
        for index in party.indices {
            guard let combatant = battle.combatants.first(where: { $0.id == party[index].id }) else { continue }
            party[index].hp = combatant.hp
            party[index].tempHP = combatant.tempHP
            party[index].conditions = combatant.conditions
        }
        run.party = party
    }
}
