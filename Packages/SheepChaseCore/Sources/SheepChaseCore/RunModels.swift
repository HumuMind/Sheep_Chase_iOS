import Foundation

public enum RunMode: String, Codable, CaseIterable, Identifiable {
    case scene
    case battle
    case map

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .scene: "场景"
        case .battle: "战斗"
        case .map: "地图"
        }
    }
}

public enum InspectorTab: String, CaseIterable, Identifiable {
    case party
    case battle
    case notes

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .party: "队伍"
        case .battle: "战斗"
        case .notes: "便签"
        }
    }
}

public struct PartyMember: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var role: String
    public var level: Int
    public var ac: Int
    public var maxHP: Int
    public var hp: Int
    public var initMod: Int
    public var passivePerception: Int
    public var tempHP: Int?
    public var conditions: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        role: String,
        level: Int,
        ac: Int,
        maxHP: Int,
        hp: Int,
        initMod: Int,
        passivePerception: Int,
        tempHP: Int? = nil,
        conditions: [String] = []
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.level = level
        self.ac = ac
        self.maxHP = maxHP
        self.hp = hp
        self.initMod = initMod
        self.passivePerception = passivePerception
        self.tempHP = tempHP
        self.conditions = conditions
    }
}

public enum NoteColor: String, Codable, CaseIterable, Identifiable {
    case yellow
    case pink
    case blue
    case green

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .yellow: "黄"
        case .pink: "粉"
        case .blue: "蓝"
        case .green: "绿"
        }
    }
}

public struct StickyNote: Identifiable, Codable, Hashable {
    public var id: UUID
    public var text: String
    public var color: NoteColor
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        text: String = "",
        color: NoteColor = .yellow,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.text = text
        self.color = color
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum BattlePhase: String, Codable {
    case select
    case initiative
    case active
}

public enum CombatantKind: String, Codable {
    case player
    case monster
}

public struct BattleMonster: Identifiable, Codable, Hashable {
    public var id: UUID
    public var baseID: String
    public var name: String
    public var initiative: Int?

    public init(id: UUID = UUID(), baseID: String, name: String, initiative: Int? = nil) {
        self.id = id
        self.baseID = baseID
        self.name = name
        self.initiative = initiative
    }
}

public struct BattleCombatant: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var kind: CombatantKind
    public var baseID: String?
    public var ac: Int
    public var hp: Int
    public var maxHP: Int
    public var initiative: Int
    public var tempHP: Int?
    public var conditions: [String]
    public var concentration: String?

    public init(
        id: UUID,
        name: String,
        kind: CombatantKind,
        baseID: String? = nil,
        ac: Int,
        hp: Int,
        maxHP: Int,
        initiative: Int,
        tempHP: Int? = nil,
        conditions: [String] = [],
        concentration: String? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.baseID = baseID
        self.ac = ac
        self.hp = hp
        self.maxHP = maxHP
        self.initiative = initiative
        self.tempHP = tempHP
        self.conditions = conditions
        self.concentration = concentration
    }
}

public struct BattleUndo: Codable {
    public var combatants: [BattleCombatant]
    public var round: Int
    public var activeID: UUID?
    public var log: [String]

    public init(combatants: [BattleCombatant], round: Int, activeID: UUID?, log: [String]) {
        self.combatants = combatants
        self.round = round
        self.activeID = activeID
        self.log = log
    }
}

public struct RunSession: Identifiable, Codable, Hashable {
    public var id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var note: String

    public init(id: UUID = UUID(), startedAt: Date = .now, endedAt: Date? = nil, note: String = "") {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.note = note
    }
}

public struct RunStateSnapshot: Codable {
    public var name: String
    public var contentVersion: String
    public var sceneID: String
    public var beatID: String
    public var mode: RunMode
    public var party: [PartyMember]
    public var flags: [String: Bool]
    public var notes: [StickyNote]
    public var battle: BattleState?
    public var lastBattle: BattleState?
    public var safety: SafetyState
    public var sessions: [RunSession]?
    public var sceneNotes: [String: String]?
    public var prepChecks: [String]?
    public var pinnedReferenceIDs: [String]?
    public var annotations: [DMAnnotation]?
    public var customBeats: [RunCustomBeat]?

    public init(
        name: String,
        contentVersion: String,
        sceneID: String,
        beatID: String,
        mode: RunMode,
        party: [PartyMember],
        flags: [String: Bool],
        notes: [StickyNote],
        battle: BattleState? = nil,
        lastBattle: BattleState? = nil,
        safety: SafetyState,
        sessions: [RunSession]? = nil,
        sceneNotes: [String: String]? = nil,
        prepChecks: [String]? = nil,
        pinnedReferenceIDs: [String]? = nil,
        annotations: [DMAnnotation]? = nil,
        customBeats: [RunCustomBeat]? = nil
    ) {
        self.name = name
        self.contentVersion = contentVersion
        self.sceneID = sceneID
        self.beatID = beatID
        self.mode = mode
        self.party = party
        self.flags = flags
        self.notes = notes
        self.battle = battle
        self.lastBattle = lastBattle
        self.safety = safety
        self.sessions = sessions
        self.sceneNotes = sceneNotes
        self.prepChecks = prepChecks
        self.pinnedReferenceIDs = pinnedReferenceIDs
        self.annotations = annotations
        self.customBeats = customBeats
    }
}

public struct RunCheckpoint: Identifiable, Codable {
    public var id: UUID
    public var createdAt: Date
    public var label: String
    public var state: RunStateSnapshot

    public init(id: UUID = UUID(), createdAt: Date = .now, label: String, state: RunStateSnapshot) {
        self.id = id
        self.createdAt = createdAt
        self.label = label
        self.state = state
    }
}

public struct SafetyState: Codable {
    public var lines: String
    public var veils: String
    public var pauseSignal: String
    public var notes: String
    public var restLog: [String]?

    public init(
        lines: String = "",
        veils: String = "",
        pauseSignal: String = "",
        notes: String = "",
        restLog: [String]? = nil
    ) {
        self.lines = lines
        self.veils = veils
        self.pauseSignal = pauseSignal
        self.notes = notes
        self.restLog = restLog
    }
}

public struct BattleState: Codable {
    public var phase: BattlePhase
    public var selectedPlayerIDs: [UUID]
    public var monsters: [BattleMonster]
    public var playerInitiatives: [String: Int]
    public var combatants: [BattleCombatant]
    public var round: Int
    public var activeID: UUID?
    public var log: [String]
    public var undo: BattleUndo?

    public init(
        phase: BattlePhase = .select,
        selectedPlayerIDs: [UUID] = [],
        monsters: [BattleMonster] = [],
        playerInitiatives: [String: Int] = [:],
        combatants: [BattleCombatant] = [],
        round: Int = 1,
        activeID: UUID? = nil,
        log: [String] = [],
        undo: BattleUndo? = nil
    ) {
        self.phase = phase
        self.selectedPlayerIDs = selectedPlayerIDs
        self.monsters = monsters
        self.playerInitiatives = playerInitiatives
        self.combatants = combatants
        self.round = round
        self.activeID = activeID
        self.log = log
        self.undo = undo
    }

    public var totalParticipants: Int {
        selectedPlayerIDs.count + monsters.count
    }
}
