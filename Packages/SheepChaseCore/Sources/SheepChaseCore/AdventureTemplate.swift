import Foundation

public struct AdventureTemplatePatch: Codable, Hashable {
    public var annotations: [DMAnnotation]
    public var customBeats: [RunCustomBeat]
    public var customNPCs: [RunCustomNPC]
    public var customMonsters: [RunCustomMonster]
    public var customMapPins: [RunCustomMapPin]
    public var encounterAdjustments: [RunEncounterAdjustment]
    public var monsterOverrides: [RunMonsterOverride]

    public init(
        annotations: [DMAnnotation] = [],
        customBeats: [RunCustomBeat] = [],
        customNPCs: [RunCustomNPC] = [],
        customMonsters: [RunCustomMonster] = [],
        customMapPins: [RunCustomMapPin] = [],
        encounterAdjustments: [RunEncounterAdjustment] = [],
        monsterOverrides: [RunMonsterOverride] = []
    ) {
        self.annotations = annotations
        self.customBeats = customBeats
        self.customNPCs = customNPCs
        self.customMonsters = customMonsters
        self.customMapPins = customMapPins
        self.encounterAdjustments = encounterAdjustments
        self.monsterOverrides = monsterOverrides
    }

    public var changeCount: Int {
        annotations.count + customBeats.count + customNPCs.count + customMonsters.count
            + customMapPins.count + encounterAdjustments.count + monsterOverrides.count
    }

    public var isEmpty: Bool {
        changeCount == 0
    }
}

public struct TemplateSaveOptions: Hashable {
    public var includeAnnotations: Bool
    public var includeCustomContent: Bool
    public var includeEncounterAdjustments: Bool
    public var includeMapPins: Bool

    public init(
        includeAnnotations: Bool = true,
        includeCustomContent: Bool = true,
        includeEncounterAdjustments: Bool = true,
        includeMapPins: Bool = true
    ) {
        self.includeAnnotations = includeAnnotations
        self.includeCustomContent = includeCustomContent
        self.includeEncounterAdjustments = includeEncounterAdjustments
        self.includeMapPins = includeMapPins
    }
}

public struct AdventureTemplate: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var summary: String
    public var baseModuleID: String
    public var baseModuleTitle: String
    public var baseContentVersion: String
    public var createdAt: Date
    public var updatedAt: Date
    public var patch: AdventureTemplatePatch

    public init(
        id: UUID = UUID(),
        name: String,
        summary: String = "",
        baseModuleID: String,
        baseModuleTitle: String,
        baseContentVersion: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        patch: AdventureTemplatePatch
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.baseModuleID = baseModuleID
        self.baseModuleTitle = baseModuleTitle
        self.baseContentVersion = baseContentVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.patch = patch
    }

    public var changeCount: Int { patch.changeCount }
}
