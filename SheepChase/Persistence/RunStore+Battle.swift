import Foundation
import Observation
import SwiftData

@MainActor
extension RunStore {
    // MARK: - Battle

    func battleState(for run: RunRecord) -> BattleState? {
        run.battle
    }

    func openBattleSetup(for run: RunRecord) {
        if run.battle == nil {
            run.battle = BattleState()
        }
        run.mode = .battle
        selectedTab = .battle
        commit(run)
    }

    func toggleBattlePlayer(_ member: PartyMember, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        if let index = battle.selectedPlayerIDs.firstIndex(of: member.id) {
            battle.selectedPlayerIDs.remove(at: index)
            battle.playerInitiatives.removeValue(forKey: member.id.uuidString)
        } else {
            battle.selectedPlayerIDs.append(member.id)
        }
        run.battle = battle
        commit(run)
    }

    func addBattleMonster(_ monster: ContentPack.Monster, in run: RunRecord) {
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

    func removeBattleMonster(_ monsterID: UUID, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        battle.monsters.removeAll { $0.id == monsterID }
        run.battle = battle
        commit(run)
    }

    func clearBattleDraft(in run: RunRecord) {
        run.battle = BattleState()
        commit(run)
    }

    func goToInitiative(in run: RunRecord) {
        guard var battle = run.battle else { return }
        for index in battle.monsters.indices {
            if battle.monsters[index].initiative == nil {
                let monster = self.monster(id: battle.monsters[index].baseID)
                battle.monsters[index].initiative = d20() + (monster?.initiativeModifier ?? 0)
            }
        }
        battle.phase = .initiative
        run.battle = battle
        commit(run)
    }

    func backToSelect(in run: RunRecord) {
        guard var battle = run.battle else { return }
        battle.phase = .select
        run.battle = battle
        commit(run)
    }

    func setPlayerInitiative(_ text: String, memberID: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        let key = memberID.uuidString
        if let value = Int(text) {
            battle.playerInitiatives[key] = value
        } else {
            battle.playerInitiatives.removeValue(forKey: key)
        }
        run.battle = battle
        commit(run)
    }

    func battleReady(_ run: RunRecord) -> Bool {
        guard let battle = run.battle, battle.totalParticipants > 0 else { return false }
        guard battle.selectedPlayerIDs.allSatisfy({
            battle.playerInitiatives[$0.uuidString] != nil
        }) else { return false }
        return battle.monsters.allSatisfy { $0.initiative != nil }
    }

    func suggestedEncounter(for run: RunRecord) -> String {
        guard let battle = run.battle else { return "先选择参战玩家" }
        let players = run.party.filter { battle.selectedPlayerIDs.contains($0.id) }
        guard !players.isEmpty else { return "先选择参战玩家" }
        let averageLevel = Double(players.reduce(0) { $0 + $1.level }) / Double(players.count)
        var wolves = max(1, players.count - 1)
        if averageLevel >= 5 { wolves += 1 }
        let bear = players.count >= 4 ? 1 : 0
        return "古兹 ×1 · 狼 ×\(wolves) · 棕熊 ×\(bear)（\(players.count) 人，平均 \(String(format: "%.1f", averageLevel)) 级）"
    }

    func startBattle(in run: RunRecord) {
        guard var battle = run.battle, battleReady(run) else { return }

        let selected = run.party.filter { battle.selectedPlayerIDs.contains($0.id) }
        var combatants: [BattleCombatant] = selected.compactMap { member in
            guard let initiative = battle.playerInitiatives[member.id.uuidString] else { return nil }
            return BattleCombatant(
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
        }

        for monsterState in battle.monsters {
            guard let stat = monster(id: monsterState.baseID), let initiative = monsterState.initiative else { continue }
            combatants.append(
                BattleCombatant(
                    id: monsterState.id,
                    name: monsterState.name,
                    kind: .monster,
                    ac: stat.ac.value,
                    hp: stat.hp.average,
                    maxHP: stat.hp.average,
                    initiative: initiative,
                    tempHP: 0
                )
            )
        }

        combatants.sort {
            if $0.initiative == $1.initiative { return $0.name < $1.name }
            return $0.initiative > $1.initiative
        }
        guard let first = combatants.first else { return }

        battle.combatants = combatants
        battle.round = 1
        battle.activeID = first.id
        battle.phase = .active
        battle.log = [
            "先攻记录 → " + combatants.map { "\($0.name) \($0.initiative)" }.joined(separator: " · "),
            "第 1 轮 · \(first.name) 的回合",
        ]
        run.battle = battle
        run.mode = .battle
        selectedTab = .battle
        commit(run)
        createCheckpoint("进入战斗", in: run)
        notify("先攻已记录，进入第 1 轮")
    }

    func nextTurn(in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .active else { return }
        guard let index = battle.combatants.firstIndex(where: { $0.id == battle.activeID }) else { return }
        battle.undo = undoSnapshot(battle)
        let next = (index + 1) % battle.combatants.count
        if next == 0 { battle.round += 1 }
        battle.activeID = battle.combatants[next].id
        battle.log.insert("第 \(battle.round) 轮 · \(battle.combatants[next].name) 的回合", at: 0)
        run.battle = battle
        commit(run)
    }

    func setTemporaryHP(_ value: Int, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle,
              let index = battle.combatants.firstIndex(where: { $0.id == id })
        else { return }
        battle.undo = undoSnapshot(battle)
        battle.combatants[index].tempHP = max(0, value)
        battle.log.insert("\(battle.combatants[index].name) 临时 HP 设为 \(max(0, value))", at: 0)
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    func adjustHP(_ delta: Int, in run: RunRecord) {
        guard let activeID = run.battle?.activeID else { return }
        adjustHP(forID: activeID, delta: delta, in: run)
    }

    func adjustHP(forID id: UUID, delta: Int, in run: RunRecord) {
        guard var battle = run.battle,
              let index = battle.combatants.firstIndex(where: { $0.id == id })
        else { return }
        battle.undo = undoSnapshot(battle)
        let before = battle.combatants[index].hp
        let beforeTemp = battle.combatants[index].tempHP ?? 0
        if delta < 0 {
            var remainingDamage = -delta
            let absorbed = min(beforeTemp, remainingDamage)
            battle.combatants[index].tempHP = beforeTemp - absorbed
            remainingDamage -= absorbed
            battle.combatants[index].hp = max(0, battle.combatants[index].hp - remainingDamage)
        } else {
            battle.combatants[index].hp = min(
                battle.combatants[index].maxHP,
                battle.combatants[index].hp + delta
            )
        }
        if battle.combatants[index].hp == 0,
           !battle.combatants[index].conditions.contains("倒地") {
            battle.combatants[index].conditions.append("倒地")
        }
        let tempNote = (beforeTemp > 0 || (battle.combatants[index].tempHP ?? 0) > 0)
            ? "（临时 HP \(beforeTemp) → \(battle.combatants[index].tempHP ?? 0)）"
            : ""
        battle.log.insert(
            "第 \(battle.round) 轮 · \(battle.combatants[index].name) \(delta > 0 ? "+" : "")\(delta) HP（\(before) → \(battle.combatants[index].hp)）\(tempNote)",
            at: 0
        )
        if delta < 0, let concentration = battle.combatants[index].concentration, !concentration.isEmpty {
            let dc = max(10, (-delta) / 2)
            battle.log.insert("专注检定：\(battle.combatants[index].name) 维持「\(concentration)」需通过 DC \(dc) 体质豁免", at: 0)
        }
        if battle.combatants[index].hp == 0, battle.combatants[index].concentration != nil {
            battle.combatants[index].concentration = nil
            battle.log.insert("\(battle.combatants[index].name) 的专注中断", at: 0)
        }
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    func toggleCondition(_ condition: String, in run: RunRecord) {
        guard var battle = run.battle,
              let activeID = battle.activeID,
              let index = battle.combatants.firstIndex(where: { $0.id == activeID })
        else { return }
        battle.undo = undoSnapshot(battle)
        if let existing = battle.combatants[index].conditions.firstIndex(of: condition) {
            battle.combatants[index].conditions.remove(at: existing)
            battle.log.insert("\(battle.combatants[index].name) 移除状态：\(condition)", at: 0)
        } else {
            battle.combatants[index].conditions.append(condition)
            battle.log.insert("\(battle.combatants[index].name) 获得状态：\(condition)", at: 0)
        }
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    func setConcentration(_ text: String, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle,
              let index = battle.combatants.firstIndex(where: { $0.id == id })
        else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        battle.undo = undoSnapshot(battle)
        battle.combatants[index].concentration = trimmed.isEmpty ? nil : trimmed
        battle.log.insert(trimmed.isEmpty ? "\(battle.combatants[index].name) 结束专注" : "\(battle.combatants[index].name) 开始专注：\(trimmed)", at: 0)
        run.battle = battle
        commit(run)
    }

    func rollDice(sides: Int, count: Int = 1, modifier: Int = 0, in run: RunRecord) -> Int {
        let rolls = (0..<max(1, count)).map { _ in Int.random(in: 1...max(2, sides)) }
        let total = rolls.reduce(0, +) + modifier
        if var battle = run.battle {
            battle.undo = undoSnapshot(battle)
            let mod = modifier == 0 ? "" : (modifier > 0 ? "+\(modifier)" : "\(modifier)")
            let detail = count > 1 ? " [\(rolls.map(String.init).joined(separator: "、"))]" : ""
            battle.log.insert("骰子 · \(count)d\(sides)\(mod) = \(total)\(detail)", at: 0)
            run.battle = battle
            commit(run)
        }
        return total
    }

    func undoBattle(in run: RunRecord) {
        guard var battle = run.battle, let undo = battle.undo else { return }
        var restoredLog = undo.log
        restoredLog.insert("已撤销上一步", at: 0)
        battle.combatants = undo.combatants
        battle.round = undo.round
        battle.activeID = undo.activeID
        battle.log = restoredLog
        battle.undo = nil
        run.battle = battle
        syncParty(run)
        commit(run)
        notify("已撤销上一步")
    }

    private func undoSnapshot(_ battle: BattleState) -> BattleUndo {
        BattleUndo(combatants: battle.combatants, round: battle.round, activeID: battle.activeID, log: battle.log)
    }

    func selectCombatant(_ id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        battle.activeID = id
        run.battle = battle
        commit(run)
    }

    func endBattle(in run: RunRecord) {
        syncParty(run)
        run.lastBattle = run.battle
        run.battle = nil
        run.mode = .scene
        selectedTab = .party
        commit(run)
        createCheckpoint("战斗结束", in: run)
        notify("战斗结束，HP 与状态已同步")
    }

    func activeCombatant(in run: RunRecord) -> BattleCombatant? {
        guard let battle = run.battle, let activeID = battle.activeID else { return nil }
        return battle.combatants.first { $0.id == activeID }
    }
}
