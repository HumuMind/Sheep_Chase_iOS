import Foundation

public extension ContentPack.Monster {
    static func custom(
        id: String,
        name: String,
        size: String,
        type: String,
        alignment: String,
        ac: ContentPack.ArmorClass,
        hp: ContentPack.HitPoints,
        speed: ContentPack.Speed,
        abilities: ContentPack.Abilities,
        skills: [String]? = nil,
        savingThrows: [String]? = nil,
        damageVulnerabilities: [String]? = nil,
        damageResistances: [String]? = nil,
        conditionImmunities: [String]? = nil,
        senses: ContentPack.Senses? = nil,
        languages: [String]? = nil,
        challenge: ContentPack.Challenge,
        traits: [ContentPack.TextPair]? = nil,
        actions: [ContentPack.TextPair],
        ruleIds: [String]? = nil,
        spellIds: [String]? = nil,
        tactics: [String]? = nil,
        sourceRef: String? = nil
    ) -> ContentPack.Monster {
        ContentPack.Monster(
            id: id,
            name: name,
            size: size,
            type: type,
            alignment: alignment,
            ac: ac,
            hp: hp,
            speed: speed,
            abilities: abilities,
            skills: skills,
            savingThrows: savingThrows,
            damageVulnerabilities: damageVulnerabilities,
            damageResistances: damageResistances,
            conditionImmunities: conditionImmunities,
            senses: senses,
            languages: languages,
            challenge: challenge,
            traits: traits,
            actions: actions,
            ruleIds: ruleIds,
            spellIds: spellIds,
            tactics: tactics,
            sourceRef: sourceRef
        )
    }
}
