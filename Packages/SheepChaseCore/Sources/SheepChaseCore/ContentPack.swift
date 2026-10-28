import Foundation

public struct ContentPack: Decodable {
    public let manifest: Manifest
    public let adventure: Adventure
    public let scenes: [AdventureScene]
    public let npcs: [NPC]
    public let monsters: [Monster]
    public let encounters: [Encounter]
    public let items: [Item]
    public let handouts: [Handout]
    public let maps: [MapData]
    public let rules: [RuleCard]
    public let spells: [SpellCard]
    public let flags: [FlagDefinition]
    public let assets: [Asset]

    public struct Manifest: Decodable {
        public let id: String
        public let title: String
        public let originalTitle: String
        public let version: String
        public let schemaVersion: Int
        public let locale: String
        public let usage: String
        public let credits: [Credit]

        public struct Credit: Decodable, Identifiable {
            public let name: String
            public let role: String
            public let url: String?
            public var id: String { name + role }
        }
    }

    public struct Adventure: Decodable {
        public let id: String
        public let title: String
        public let summary: String
        public let level: Range
        public let players: Range
        public let durationMinutes: Int
        public let contentWarnings: [String]
        public let sceneOrder: [String]
        public let startingScene: String

        public struct Range: Decodable {
            public let min: Int
            public let max: Int
        }
    }

    public struct AdventureScene: Decodable, Identifiable {
        public let id: String
        public let order: Int
        public let title: String
        public let summary: String
        public let readAloud: String?
        public let dmText: String?
        public let beats: [Beat]
        public let branches: [Branch]?
        public let npcIds: [String]?
        public let encounterIds: [String]?
        public let handoutIds: [String]?
        public let ruleIds: [String]?
        public let spellIds: [String]?
        public let mapIds: [String]?
        public let itemIds: [String]?
        public let dmNotes: String?
        public let fadeToBlack: String?
        public let sourceRef: String?
    }

    public struct Beat: Decodable, Identifiable {
        public let id: String
        public let title: String
        public let type: String
        public let text: String
        public let readAloud: String?
        public let requiresFlag: String?
        public let npcIds: [String]?
        public let encounterIds: [String]?
        public let handoutIds: [String]?
        public let ruleIds: [String]?
        public let spellIds: [String]?
        public let mapIds: [String]?
        public let itemIds: [String]?
    }

    public struct Branch: Decodable, Identifiable {
        public let id: String
        public let label: String
        public let requiresFlag: String?
        public let text: String
    }

    public struct Monster: Decodable, Identifiable {
        public let id: String
        public let name: String
        public let size: String
        public let type: String
        public let alignment: String
        public let ac: ArmorClass
        public let hp: HitPoints
        public let speed: Speed
        public let abilities: Abilities
        public let skills: [String]?
        public let savingThrows: [String]?
        public let damageVulnerabilities: [String]?
        public let damageResistances: [String]?
        public let conditionImmunities: [String]?
        public let senses: Senses?
        public let languages: [String]?
        public let challenge: Challenge
        public let traits: [TextPair]?
        public let actions: [TextPair]
        public let ruleIds: [String]?
        public let spellIds: [String]?
        public let tactics: [String]?
        public let sourceRef: String?

        public var initiativeModifier: Int {
            Int(floor(Double(abilities.dex - 10) / 2.0))
        }
    }

    public struct ArmorClass: Decodable {
        public let value: Int
        public let note: String?
    }

    public struct HitPoints: Decodable {
        public let average: Int
        public let formula: String
    }

    public struct Speed: Decodable {
        public let walk: Int
        public let climb: Int?
        public let fly: Int?
    }

    public struct Abilities: Decodable {
        public let str: Int
        public let dex: Int
        public let con: Int
        public let int: Int
        public let wis: Int
        public let cha: Int
    }

    public struct Senses: Decodable {
        public let passivePerception: Int
    }

    public struct Challenge: Decodable {
        public let rating: Double
        public let xp: Int
    }

    public struct TextPair: Decodable, Identifiable {
        public let name: String
        public let text: String
        public var id: String { name }
    }

    public struct Encounter: Decodable, Identifiable {
        public let id: String
        public let title: String
        public let summary: String
        public let combatants: [CombatantRef]
        public let tactics: [String]?
        public let terrain: String?
        public let trigger: String?
        public let difficulty: String?
    }

    public struct CombatantRef: Decodable {
        public let monsterId: String
        public let count: Int
        public let label: String?
    }

    public struct RuleCard: Decodable, Identifiable {
        public let id: String
        public let term: String
        public let aliases: [String]
        public let category: String
        public let summary: String
        public let pageRef: String
    }

    public struct SpellCard: Decodable, Identifiable {
        public let id: String
        public let name: String
        public let aliases: [String]
        public let level: Int
        public let school: String
        public let castingTime: String
        public let range: String
        public let components: String?
        public let duration: String
        public let concentration: Bool
        public let ritual: Bool?
        public let summary: String
        public let pageRef: String
    }

    public struct NPC: Decodable, Identifiable {
        public let id: String
        public let name: String
        public let role: String
        public let publicDescription: String
        public let dmDescription: String
        public let personality: [String]
        public let voice: String
        public let motivation: String
        public let attitude: String
        public let knows: [String]
        public let secrets: [String]
        public let wants: [String]
        public let sampleLines: [String]
        public let keyCharacteristics: [String]?
        public let relationships: [Relationship]?
        public let portraitAssetId: String?
        public let sourceRef: String?

        public struct Relationship: Decodable, Identifiable {
            public let label: String
            public let note: String
            public var id: String { label }
        }
    }

    public struct Item: Decodable, Identifiable {
        public let id: String
        public let name: String
        public let kind: String
        public let summary: String
        public let pageRef: String?
        public let sourceRef: String?
    }

    public struct Handout: Decodable, Identifiable {
        public let id: String
        public let title: String
        public let kind: String
        public let playerText: String
        public let dmText: String?
        public let imageAssetId: String?
    }

    public struct MapData: Decodable, Identifiable {
        public let id: String
        public let title: String
        public let imageAssetId: String
        public let pins: [Pin]

        public struct Pin: Decodable, Identifiable {
            public let id: String
            public let label: String
            public let x: Double
            public let y: Double
            public let dmOnly: Bool
            public let description: String?
        }
    }

    public struct Asset: Decodable, Identifiable {
        public let id: String
        public let path: String
        public let kind: String
        public let exportFilename: String
        public let credit: String?
    }

    public struct FlagDefinition: Decodable, Identifiable {
        public let id: String
        public let label: String
        public let description: String
        public let defaultValue: Bool
    }
}
