import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func monsterOverride(for monsterID: String, in run: RunRecord) -> RunMonsterOverride? {
        run.monsterOverrides.first { $0.monsterID == monsterID }
    }

    public func setMonsterOverride(
        monsterID: String,
        ac: Int?,
        hp: Int?,
        initiativeModifier: Int?,
        note: String,
        in run: RunRecord
    ) {
        var overrides = run.monsterOverrides
        overrides.removeAll { $0.monsterID == monsterID }
        if ac != nil || hp != nil || initiativeModifier != nil || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            overrides.append(
                RunMonsterOverride(
                    monsterID: monsterID,
                    ac: ac,
                    hp: hp,
                    initiativeModifier: initiativeModifier,
                    note: note.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        }
        run.monsterOverrides = overrides
        commit(run)
    }

    public func clearMonsterOverride(monsterID: String, in run: RunRecord) {
        run.monsterOverrides.removeAll { $0.monsterID == monsterID }
        commit(run)
    }

    public func monsterForBattle(id: String, in run: RunRecord) -> ContentPack.Monster? {
        guard let monster = monster(id: id, in: run) else { return nil }
        return applyingMonsterOverride(monster, in: run)
    }

    func applyingMonsterOverride(_ monster: ContentPack.Monster, in run: RunRecord) -> ContentPack.Monster {
        guard let override = monsterOverride(for: monster.id, in: run) else { return monster }
        let dex = 10 + (override.initiativeModifier ?? monster.initiativeModifier) * 2
        return ContentPack.Monster.custom(
            id: monster.id,
            name: monster.name,
            size: monster.size,
            type: monster.type,
            alignment: monster.alignment,
            ac: ContentPack.ArmorClass(value: override.ac ?? monster.ac.value, note: monster.ac.note),
            hp: ContentPack.HitPoints(average: override.hp ?? monster.hp.average, formula: monster.hp.formula),
            speed: monster.speed,
            abilities: ContentPack.Abilities(
                str: monster.abilities.str,
                dex: dex,
                con: monster.abilities.con,
                int: monster.abilities.int,
                wis: monster.abilities.wis,
                cha: monster.abilities.cha
            ),
            skills: monster.skills,
            savingThrows: monster.savingThrows,
            damageVulnerabilities: monster.damageVulnerabilities,
            damageResistances: monster.damageResistances,
            conditionImmunities: monster.conditionImmunities,
            senses: monster.senses,
            languages: monster.languages,
            challenge: monster.challenge,
            traits: monster.traits,
            actions: monster.actions,
            ruleIds: monster.ruleIds,
            spellIds: monster.spellIds,
            tactics: monster.tactics,
            sourceRef: monster.sourceRef
        )
    }
}
