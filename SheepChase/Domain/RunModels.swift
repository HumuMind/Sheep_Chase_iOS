import Foundation

enum RunMode: String, Codable, CaseIterable, Identifiable {
    case scene
    case battle
    case map

    var id: String { rawValue }
    var title: String {
        switch self {
        case .scene: "场景"
        case .battle: "战斗"
        case .map: "地图"
        }
    }
}

enum InspectorTab: String, CaseIterable, Identifiable {
    case party
    case battle
    case notes
    case rules

    var id: String { rawValue }
    var title: String {
        switch self {
        case .party: "队伍"
        case .battle: "战斗"
        case .notes: "便签"
        case .rules: "速查"
        }
    }
}

struct PartyMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var role: String
    var level: Int
    var ac: Int
    var maxHP: Int
    var hp: Int
    var initMod: Int
    var passivePerception: Int
    var tempHP: Int? = nil
    var conditions: [String] = []
}

enum NoteColor: String, Codable, CaseIterable, Identifiable {
    case yellow
    case pink
    case blue
    case green

    var id: String { rawValue }
    var title: String {
        switch self {
        case .yellow: "黄"
        case .pink: "粉"
        case .blue: "蓝"
        case .green: "绿"
        }
    }
}

struct StickyNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var text: String = ""
    var color: NoteColor = .yellow
    var createdAt: Date = .now
    var updatedAt: Date = .now
}

enum BattlePhase: String, Codable {
    case select
    case initiative
    case active
}

enum CombatantKind: String, Codable {
    case player
    case monster
}

struct BattleMonster: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var baseID: String
    var name: String
    var initiative: Int?
}

struct BattleCombatant: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var kind: CombatantKind
    var baseID: String? = nil
    var ac: Int
    var hp: Int
    var maxHP: Int
    var initiative: Int
    var tempHP: Int? = nil
    var conditions: [String] = []
    var concentration: String? = nil
}

struct BattleUndo: Codable {
    var combatants: [BattleCombatant]
    var round: Int
    var activeID: UUID?
    var log: [String]
}

struct RunSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var startedAt: Date = .now
    var endedAt: Date?
    var note: String = ""
}

struct RunStateSnapshot: Codable {
    var name: String
    var contentVersion: String
    var sceneID: String
    var beatID: String
    var mode: RunMode
    var party: [PartyMember]
    var flags: [String: Bool]
    var notes: [StickyNote]
    var battle: BattleState?
    var lastBattle: BattleState?
    var safety: SafetyState
    var sessions: [RunSession]?
    var sceneNotes: [String: String]?
    var prepChecks: [String]?
}

struct RunCheckpoint: Identifiable, Codable {
    var id: UUID = UUID()
    var createdAt: Date = .now
    var label: String
    var state: RunStateSnapshot
}

struct SafetyState: Codable {
    var lines: String = ""
    var veils: String = ""
    var pauseSignal: String = ""
    var notes: String = ""
    var restLog: [String]? = nil
}

struct BattleState: Codable {
    var phase: BattlePhase = .select
    var selectedPlayerIDs: [UUID] = []
    var monsters: [BattleMonster] = []
    var playerInitiatives: [String: Int] = [:]
    var combatants: [BattleCombatant] = []
    var round: Int = 1
    var activeID: UUID?
    var log: [String] = []
    var undo: BattleUndo? = nil

    var totalParticipants: Int {
        selectedPlayerIDs.count + monsters.count
    }
}
