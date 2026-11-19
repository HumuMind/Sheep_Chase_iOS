import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func encounterAdjustment(for encounterID: String, in run: RunRecord) -> RunEncounterAdjustment? {
        run.encounterAdjustments.first { $0.encounterID == encounterID }
    }

    public func setEncounterAdjustment(
        encounterID: String,
        combatants: [RunEncounterCombatant],
        note: String,
        in run: RunRecord
    ) {
        var adjustments = run.encounterAdjustments
        adjustments.removeAll { $0.encounterID == encounterID }
        let cleaned = combatants.filter { $0.count > 0 }
        if !cleaned.isEmpty || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            adjustments.append(
                RunEncounterAdjustment(
                    encounterID: encounterID,
                    combatants: cleaned,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        }
        run.encounterAdjustments = adjustments
        commit(run)
    }

    public func clearEncounterAdjustment(encounterID: String, in run: RunRecord) {
        run.encounterAdjustments.removeAll { $0.encounterID == encounterID }
        commit(run)
    }

    public func prepareEncounter(_ encounterID: String, in run: RunRecord) {
        let baseCombatants: [RunEncounterCombatant]
        if let adjustment = encounterAdjustment(for: encounterID, in: run) {
            baseCombatants = adjustment.combatants
        } else if let encounter = encounter(id: encounterID) {
            baseCombatants = encounter.combatants.map {
                RunEncounterCombatant(monsterID: $0.monsterId, count: $0.count, label: $0.label ?? "")
            }
        } else {
            return
        }

        openBattleSetup(for: run)
        guard var battle = run.battle, battle.monsters.isEmpty else { return }
        battle.encounterID = encounterID
        run.battle = battle
        for combatant in baseCombatants {
            guard let monster = monsterForBattle(id: combatant.monsterID, in: run) else { continue }
            for _ in 0..<max(1, combatant.count) {
                addBattleMonster(monster, in: run)
            }
        }
    }
}
