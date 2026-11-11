import Foundation
import SheepChaseCore

public enum BattleEngine {
    public static func togglePlayer(_ memberID: UUID, battle: inout BattleState) {
        guard battle.phase == .select else { return }
        if let index = battle.selectedPlayerIDs.firstIndex(of: memberID) {
            battle.selectedPlayerIDs.remove(at: index)
            battle.playerInitiatives.removeValue(forKey: memberID.uuidString)
        } else {
            battle.selectedPlayerIDs.append(memberID)
        }
    }

    public static func setPlayerInitiative(_ text: String, memberID: UUID, battle: inout BattleState) {
        let key = memberID.uuidString
        if let value = Int(text) {
            battle.playerInitiatives[key] = value
        } else {
            battle.playerInitiatives.removeValue(forKey: key)
        }
    }

    public static func goToInitiative(
        battle: inout BattleState,
        monsters: [ContentPack.Monster],
        allies: [BattleAlly] = [],
        d20Roll: () -> Int = { Int.random(in: 1...20) }
    ) {
        for index in battle.monsters.indices where battle.monsters[index].initiative == nil {
            let stat = monsters.first { $0.id == battle.monsters[index].baseID }
            battle.monsters[index].initiative = d20Roll() + (stat?.initiativeModifier ?? 0)
        }
        var currentAllies = battle.allies ?? allies
        for index in currentAllies.indices where currentAllies[index].initiative == nil {
            currentAllies[index].initiative = d20Roll() + currentAllies[index].initiativeModifier
        }
        battle.allies = currentAllies
        battle.phase = .initiative
    }

    public static func backToSelect(battle: inout BattleState) {
        battle.phase = .select
    }

    public static func battleReady(_ battle: BattleState) -> Bool {
        guard battle.totalParticipants > 0 else { return false }
        guard battle.selectedPlayerIDs.allSatisfy({
            battle.playerInitiatives[$0.uuidString] != nil
        }) else { return false }
        return battle.monsters.allSatisfy { $0.initiative != nil }
    }

    public static func suggestedEncounter(_ battle: BattleState, players: [PartyMember]) -> String {
        let selected = players.filter { battle.selectedPlayerIDs.contains($0.id) }
        guard !selected.isEmpty else { return "先选择参战玩家" }
        let averageLevel = Double(selected.reduce(0) { $0 + $1.level }) / Double(selected.count)
        var wolves = max(1, selected.count - 1)
        if averageLevel >= 5 { wolves += 1 }
        let bear = selected.count >= 4 ? 1 : 0
        return "古兹 ×1 · 狼 ×\(wolves) · 棕熊 ×\(bear)（\(selected.count) 人，平均 \(String(format: "%.1f", averageLevel)) 级）"
    }

    @discardableResult
    public static func start(
        battle: inout BattleState,
        players: [PartyMember],
        monsters: [ContentPack.Monster],
        allies: [BattleAlly] = []
    ) -> Bool {
        guard battleReady(battle) else { return false }

        let selected = players.filter { battle.selectedPlayerIDs.contains($0.id) }
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
            guard let stat = monsters.first(where: { $0.id == monsterState.baseID }),
                  let initiative = monsterState.initiative else { continue }
            combatants.append(
                BattleCombatant(
                    id: monsterState.id,
                    name: monsterState.name,
                    kind: .monster,
                    baseID: monsterState.baseID,
                    ac: stat.ac.value,
                    hp: stat.hp.average,
                    maxHP: stat.hp.average,
                    initiative: initiative,
                    tempHP: 0
                )
            )
        }

        for ally in battle.allies ?? allies {
            guard let initiative = ally.initiative else { continue }
            combatants.append(
                BattleCombatant(
                    id: ally.id,
                    name: ally.name,
                    kind: .npc,
                    baseID: ally.baseID,
                    ac: ally.ac,
                    hp: ally.hp,
                    maxHP: ally.maxHP,
                    initiative: initiative,
                    tempHP: 0
                )
            )
        }

        combatants.sort {
            if $0.initiative == $1.initiative { return $0.name < $1.name }
            return $0.initiative > $1.initiative
        }
        guard let first = combatants.first else { return false }

        battle.combatants = combatants
        battle.round = 1
        battle.activeID = first.id
        battle.phase = .active
        battle.log = [
            "先攻记录 → " + combatants.map { "\($0.name) \($0.initiative)" }.joined(separator: " · "),
            "第 1 轮 · \(first.name) 的回合",
        ]
        return true
    }

    public static func nextTurn(battle: inout BattleState) {
        guard battle.phase == .active,
              let index = battle.combatants.firstIndex(where: { $0.id == battle.activeID })
        else { return }
        battle.undo = undoSnapshot(battle)
        let next = (index + 1) % battle.combatants.count
        if next == 0 { battle.round += 1 }
        battle.activeID = battle.combatants[next].id
        battle.log.insert("第 \(battle.round) 轮 · \(battle.combatants[next].name) 的回合", at: 0)
    }

    public static func setHP(_ value: Int, forID id: UUID, battle: inout BattleState) {
        guard let index = battle.combatants.firstIndex(where: { $0.id == id }) else { return }
        battle.undo = undoSnapshot(battle)
        let before = battle.combatants[index].hp
        let clamped = min(max(0, value), battle.combatants[index].maxHP)
        battle.combatants[index].hp = clamped
        if clamped == 0, !battle.combatants[index].conditions.contains("倒地") {
            battle.combatants[index].conditions.append("倒地")
        }
        battle.log.insert(
            "第 \(battle.round) 轮 · \(battle.combatants[index].name) HP 设为 \(clamped)（原 \(before)）",
            at: 0
        )
        if clamped == 0, battle.combatants[index].concentration != nil {
            battle.combatants[index].concentration = nil
            battle.log.insert("\(battle.combatants[index].name) 的专注中断", at: 0)
        }
    }

    public static func setNotes(_ text: String, forID id: UUID, battle: inout BattleState) {
        guard let index = battle.combatants.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        battle.combatants[index].notes = trimmed.isEmpty ? nil : trimmed
    }

    public static func setTemporaryHP(_ value: Int, forID id: UUID, battle: inout BattleState) {
        guard let index = battle.combatants.firstIndex(where: { $0.id == id }) else { return }
        battle.undo = undoSnapshot(battle)
        battle.combatants[index].tempHP = max(0, value)
        battle.log.insert("\(battle.combatants[index].name) 临时 HP 设为 \(max(0, value))", at: 0)
    }

    public static func adjustHP(_ delta: Int, battle: inout BattleState) {
        guard let activeID = battle.activeID else { return }
        adjustHP(forID: activeID, delta: delta, battle: &battle)
    }

    public static func adjustHP(forID id: UUID, delta: Int, battle: inout BattleState) {
        guard let index = battle.combatants.firstIndex(where: { $0.id == id }) else { return }
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
    }

    public static func toggleCondition(_ condition: String, battle: inout BattleState) {
        guard let activeID = battle.activeID,
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
    }

    public static func setConcentration(_ text: String, forID id: UUID, battle: inout BattleState) {
        guard let index = battle.combatants.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        battle.undo = undoSnapshot(battle)
        battle.combatants[index].concentration = trimmed.isEmpty ? nil : trimmed
        battle.log.insert(trimmed.isEmpty ? "\(battle.combatants[index].name) 结束专注" : "\(battle.combatants[index].name) 开始专注：\(trimmed)", at: 0)
    }

    public static func rollDice(
        sides: Int,
        count: Int = 1,
        modifier: Int = 0,
        battle: inout BattleState,
        dieRoll: (Int) -> Int = { sides in Int.random(in: 1...max(2, sides)) }
    ) -> Int {
        let rolls = (0..<max(1, count)).map { _ in dieRoll(sides) }
        let total = rolls.reduce(0, +) + modifier
        battle.undo = undoSnapshot(battle)
        let mod = modifier == 0 ? "" : (modifier > 0 ? "+\(modifier)" : "\(modifier)")
        let detail = count > 1 ? " [\(rolls.map(String.init).joined(separator: "、"))]" : ""
        battle.log.insert("骰子 · \(count)d\(sides)\(mod) = \(total)\(detail)", at: 0)
        return total
    }

    @discardableResult
    public static func undo(battle: inout BattleState) -> Bool {
        guard let undo = battle.undo else { return false }
        var restoredLog = undo.log
        restoredLog.insert("已撤销上一步", at: 0)
        battle.combatants = undo.combatants
        battle.round = undo.round
        battle.activeID = undo.activeID
        battle.log = restoredLog
        battle.undo = nil
        return true
    }

    public static func selectCombatant(_ id: UUID, battle: inout BattleState) {
        battle.activeID = id
    }

    public static func activeCombatant(_ battle: BattleState) -> BattleCombatant? {
        guard let activeID = battle.activeID else { return nil }
        return battle.combatants.first { $0.id == activeID }
    }

    private static func undoSnapshot(_ battle: BattleState) -> BattleUndo {
        BattleUndo(combatants: battle.combatants, round: battle.round, activeID: battle.activeID, log: battle.log)
    }
}
