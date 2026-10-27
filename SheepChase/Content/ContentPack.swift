import Foundation

struct ContentPack: Decodable {
    let manifest: Manifest
    let adventure: Adventure
    let scenes: [AdventureScene]
    let monsters: [Monster]
    let encounters: [Encounter]
    let rules: [RuleCard]
    let spells: [SpellCard]
    let flags: [FlagDefinition]

    struct Manifest: Decodable {
        let id: String
        let title: String
        let version: String
        let schemaVersion: Int
    }

    struct Adventure: Decodable {
        let id: String
        let title: String
        let summary: String
        let level: Range
        let players: Range
        let durationMinutes: Int
        let contentWarnings: [String]
        let sceneOrder: [String]
        let startingScene: String

        struct Range: Decodable {
            let min: Int
            let max: Int
        }
    }

    struct AdventureScene: Decodable, Identifiable {
        let id: String
        let order: Int
        let title: String
        let summary: String
        let readAloud: String?
        let dmText: String?
        let beats: [Beat]
        let branches: [Branch]?
        let npcIds: [String]?
        let encounterIds: [String]?
        let handoutIds: [String]?
        let ruleIds: [String]?
        let spellIds: [String]?
        let dmNotes: String?
        let sourceRef: String?
    }

    struct Beat: Decodable, Identifiable {
        let id: String
        let title: String
        let type: String
        let text: String
        let readAloud: String?
        let requiresFlag: String?
        let npcIds: [String]?
        let encounterIds: [String]?
        let handoutIds: [String]?
        let spellIds: [String]?
    }

    struct Branch: Decodable, Identifiable {
        let id: String
        let label: String
        let requiresFlag: String?
        let text: String
    }

    struct Monster: Decodable, Identifiable {
        let id: String
        let name: String
        let size: String
        let type: String
        let alignment: String
        let ac: ArmorClass
        let hp: HitPoints
        let speed: Speed
        let abilities: Abilities
        let skills: [String]?
        let senses: Senses?
        let languages: [String]?
        let challenge: Challenge
        let traits: [TextPair]?
        let actions: [TextPair]
        let tactics: [String]?
        let sourceRef: String?

        var initiativeModifier: Int {
            Int(floor(Double(abilities.dex - 10) / 2.0))
        }
    }

    struct ArmorClass: Decodable {
        let value: Int
        let note: String?
    }

    struct HitPoints: Decodable {
        let average: Int
        let formula: String
    }

    struct Speed: Decodable {
        let walk: Int
        let climb: Int?
        let fly: Int?
    }

    struct Abilities: Decodable {
        let str: Int
        let dex: Int
        let con: Int
        let int: Int
        let wis: Int
        let cha: Int
    }

    struct Senses: Decodable {
        let passivePerception: Int
    }

    struct Challenge: Decodable {
        let rating: Double
        let xp: Int
    }

    struct TextPair: Decodable, Identifiable {
        let name: String
        let text: String
        var id: String { name }
    }

    struct Encounter: Decodable, Identifiable {
        let id: String
        let title: String
        let summary: String
        let combatants: [CombatantRef]
        let tactics: [String]?
        let terrain: String?
        let trigger: String?
        let difficulty: String?
    }

    struct CombatantRef: Decodable {
        let monsterId: String
        let count: Int
        let label: String?
    }

    struct RuleCard: Decodable, Identifiable {
        let id: String
        let term: String
        let aliases: [String]
        let category: String
        let summary: String
        let pageRef: String
    }

    struct SpellCard: Decodable, Identifiable {
        let id: String
        let name: String
        let aliases: [String]
        let level: Int
        let school: String
        let castingTime: String
        let range: String
        let duration: String
        let concentration: Bool
        let summary: String
        let pageRef: String
    }

    struct FlagDefinition: Decodable, Identifiable {
        let id: String
        let label: String
        let description: String
        let defaultValue: Bool
    }
}

enum ContentStore {
    static func load() -> ContentPack {
        guard
            let url = Bundle.main.url(forResource: "ContentPack", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let pack = try? JSONDecoder().decode(ContentPack.self, from: data)
        else {
            fatalError("ContentPack.json 缺失或无法解码")
        }
        return pack
    }
}
