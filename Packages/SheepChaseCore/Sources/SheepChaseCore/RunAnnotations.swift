import Foundation

public enum DMAnnotationTargetKind: String, Codable, CaseIterable, Hashable {
    case scene
    case readAloud
    case beat
    case npc
    case monster
    case item
    case spell
    case rule
    case handout
    case encounter
    case guide
}

public enum DMAnnotationMode: String, Codable, CaseIterable {
    case append
    case replace

    public var title: String {
        switch self {
        case .append: "追加在原文后"
        case .replace: "替换原文显示"
        }
    }
}

public struct DMAnnotation: Identifiable, Codable, Hashable {
    public var id: UUID
    public var targetKind: DMAnnotationTargetKind
    public var targetID: String
    public var mode: DMAnnotationMode
    public var text: String
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        targetKind: DMAnnotationTargetKind,
        targetID: String,
        mode: DMAnnotationMode = .append,
        text: String,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.targetKind = targetKind
        self.targetID = targetID
        self.mode = mode
        self.text = text
        self.updatedAt = updatedAt
    }
}

public struct RunCustomBeat: Identifiable, Codable, Hashable {
    public var id: UUID
    public var sceneID: String
    public var title: String
    public var type: String
    public var text: String
    public var readAloud: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        sceneID: String,
        title: String,
        type: String = "note",
        text: String,
        readAloud: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sceneID = sceneID
        self.title = title
        self.type = type
        self.text = text
        self.readAloud = readAloud
        self.createdAt = createdAt
    }
}

public struct RunCustomMapPin: Identifiable, Codable, Hashable {
    public var id: UUID
    public var mapID: String
    public var x: Double
    public var y: Double
    public var label: String
    public var note: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        mapID: String,
        x: Double,
        y: Double,
        label: String,
        note: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.mapID = mapID
        self.x = x
        self.y = y
        self.label = label
        self.note = note
        self.createdAt = createdAt
    }
}

public struct RunCustomNPC: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var role: String
    public var description: String
    public var keyCharacteristics: [String]
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        role: String,
        description: String,
        keyCharacteristics: [String] = [],
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.description = description
        self.keyCharacteristics = keyCharacteristics
        self.createdAt = createdAt
    }
}

public struct RunCustomMonster: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var size: String
    public var type: String
    public var alignment: String
    public var ac: Int
    public var hp: Int
    public var initiativeModifier: Int
    public var actionText: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        size: String = "中型",
        type: String = "怪兽",
        alignment: String = "无阵营",
        ac: Int,
        hp: Int,
        initiativeModifier: Int = 0,
        actionText: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.type = type
        self.alignment = alignment
        self.ac = ac
        self.hp = hp
        self.initiativeModifier = initiativeModifier
        self.actionText = actionText
        self.createdAt = createdAt
    }
}

public struct RunEncounterCombatant: Identifiable, Codable, Hashable {
    public var id: UUID
    public var monsterID: String
    public var count: Int
    public var label: String

    public init(id: UUID = UUID(), monsterID: String, count: Int, label: String = "") {
        self.id = id
        self.monsterID = monsterID
        self.count = max(1, count)
        self.label = label
    }
}

public struct RunEncounterAdjustment: Identifiable, Codable, Hashable {
    public var id: UUID
    public var encounterID: String
    public var combatants: [RunEncounterCombatant]
    public var note: String
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        encounterID: String,
        combatants: [RunEncounterCombatant],
        note: String = "",
        updatedAt: Date = .now
    ) {
        self.id = id
        self.encounterID = encounterID
        self.combatants = combatants
        self.note = note
        self.updatedAt = updatedAt
    }
}

public struct RunMonsterOverride: Identifiable, Codable, Hashable {
    public var id: UUID
    public var monsterID: String
    public var ac: Int?
    public var hp: Int?
    public var initiativeModifier: Int?
    public var note: String
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        monsterID: String,
        ac: Int? = nil,
        hp: Int? = nil,
        initiativeModifier: Int? = nil,
        note: String = "",
        updatedAt: Date = .now
    ) {
        self.id = id
        self.monsterID = monsterID
        self.ac = ac
        self.hp = hp
        self.initiativeModifier = initiativeModifier
        self.note = note
        self.updatedAt = updatedAt
    }
}
