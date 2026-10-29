import Foundation
import SheepChaseCore
import SwiftData

@Model
public final class RunRecord {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date
    public var sceneID: String
    public var beatID: String
    public var modeRaw: String
    public var partyData: Data
    public var flagsData: Data
    public var notesData: Data
    public var battleData: Data?
    public var lastBattleData: Data?
    public var safetyData: Data?
    public var sessionsData: Data?
    public var checkpointsData: Data?
    public var sceneNotesData: Data?
    public var prepData: Data?
    public var pinnedReferenceData: Data?
    public var annotationsData: Data?
    public var customBeatsData: Data?
    public var customMapPinsData: Data?
    public var customNPCsData: Data?
    public var customMonstersData: Data?
    public var encounterAdjustmentsData: Data?
    public var monsterOverridesData: Data?
    public var isArchived: Bool = false
    public var contentVersion: String = ""

    public init(
        name: String,
        sceneID: String = "scene-1",
        beatID: String = "sheep-arrives",
        contentVersion: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = .now
        self.updatedAt = .now
        self.sceneID = sceneID
        self.beatID = beatID
        self.modeRaw = RunMode.scene.rawValue
        self.partyData = Self.encode([PartyMember]())
        self.flagsData = Self.encode([String: Bool]())
        self.notesData = Self.encode([StickyNote]())
        self.battleData = nil
        self.lastBattleData = nil
        self.safetyData = Self.encode(SafetyState())
        self.sessionsData = Self.encode([RunSession]())
        self.checkpointsData = Self.encode([RunCheckpoint]())
        self.sceneNotesData = Self.encode([String: String]())
        self.prepData = Self.encode([String]())
        self.pinnedReferenceData = nil
        self.annotationsData = nil
        self.customBeatsData = nil
        self.customMapPinsData = nil
        self.customNPCsData = nil
        self.customMonstersData = nil
        self.encounterAdjustmentsData = nil
        self.monsterOverridesData = nil
        self.isArchived = false
        self.contentVersion = contentVersion
    }

    public var mode: RunMode {
        get { RunMode(rawValue: modeRaw) ?? .scene }
        set { modeRaw = newValue.rawValue }
    }

    public var party: [PartyMember] {
        get { Self.decode([PartyMember].self, from: partyData) ?? [] }
        set { partyData = Self.encode(newValue) }
    }

    public var flags: [String: Bool] {
        get { Self.decode([String: Bool].self, from: flagsData) ?? [:] }
        set { flagsData = Self.encode(newValue) }
    }

    public var stickyNotes: [StickyNote] {
        get { Self.decode([StickyNote].self, from: notesData) ?? [] }
        set { notesData = Self.encode(newValue) }
    }

    public var battle: BattleState? {
        get {
            guard let battleData else { return nil }
            return Self.decode(BattleState.self, from: battleData)
        }
        set {
            battleData = newValue.flatMap { Self.encodeOptional($0) }
        }
    }

    public var lastBattle: BattleState? {
        get {
            guard let lastBattleData else { return nil }
            return Self.decode(BattleState.self, from: lastBattleData)
        }
        set {
            lastBattleData = newValue.flatMap { Self.encodeOptional($0) }
        }
    }

    public var safety: SafetyState {
        get {
            guard let safetyData else { return SafetyState() }
            return Self.decode(SafetyState.self, from: safetyData) ?? SafetyState()
        }
        set {
            safetyData = Self.encode(newValue)
        }
    }

    public var sessions: [RunSession] {
        get {
            guard let sessionsData else { return [] }
            return Self.decode([RunSession].self, from: sessionsData) ?? []
        }
        set {
            sessionsData = Self.encode(newValue)
        }
    }

    public var checkpoints: [RunCheckpoint] {
        get {
            guard let checkpointsData else { return [] }
            return Self.decode([RunCheckpoint].self, from: checkpointsData) ?? []
        }
        set {
            checkpointsData = Self.encode(newValue)
        }
    }

    public var sceneNotes: [String: String] {
        get {
            guard let sceneNotesData else { return [:] }
            return Self.decode([String: String].self, from: sceneNotesData) ?? [:]
        }
        set {
            sceneNotesData = Self.encode(newValue)
        }
    }

    public var prepChecks: [String] {
        get {
            guard let prepData else { return [] }
            return Self.decode([String].self, from: prepData) ?? []
        }
        set {
            prepData = Self.encode(newValue)
        }
    }

    public var pinnedReferenceIDs: [String] {
        get {
            guard let pinnedReferenceData else { return [] }
            return Self.decode([String].self, from: pinnedReferenceData) ?? []
        }
        set {
            pinnedReferenceData = Self.encode(newValue)
        }
    }

    public var annotations: [DMAnnotation] {
        get {
            guard let annotationsData else { return [] }
            return Self.decode([DMAnnotation].self, from: annotationsData) ?? []
        }
        set {
            annotationsData = Self.encode(newValue)
        }
    }

    public var customBeats: [RunCustomBeat] {
        get {
            guard let customBeatsData else { return [] }
            return Self.decode([RunCustomBeat].self, from: customBeatsData) ?? []
        }
        set {
            customBeatsData = Self.encode(newValue)
        }
    }

    public var customMapPins: [RunCustomMapPin] {
        get {
            guard let customMapPinsData else { return [] }
            return Self.decode([RunCustomMapPin].self, from: customMapPinsData) ?? []
        }
        set {
            customMapPinsData = Self.encode(newValue)
        }
    }

    public var customNPCs: [RunCustomNPC] {
        get {
            guard let customNPCsData else { return [] }
            return Self.decode([RunCustomNPC].self, from: customNPCsData) ?? []
        }
        set {
            customNPCsData = Self.encode(newValue)
        }
    }

    public var customMonsters: [RunCustomMonster] {
        get {
            guard let customMonstersData else { return [] }
            return Self.decode([RunCustomMonster].self, from: customMonstersData) ?? []
        }
        set {
            customMonstersData = Self.encode(newValue)
        }
    }

    public var encounterAdjustments: [RunEncounterAdjustment] {
        get {
            guard let encounterAdjustmentsData else { return [] }
            return Self.decode([RunEncounterAdjustment].self, from: encounterAdjustmentsData) ?? []
        }
        set { encounterAdjustmentsData = Self.encode(newValue) }
    }

    public var monsterOverrides: [RunMonsterOverride] {
        get {
            guard let monsterOverridesData else { return [] }
            return Self.decode([RunMonsterOverride].self, from: monsterOverridesData) ?? []
        }
        set { monsterOverridesData = Self.encode(newValue) }
    }

    public var stateSnapshot: RunStateSnapshot {
        RunStateSnapshot(
            name: name,
            contentVersion: contentVersion,
            sceneID: sceneID,
            beatID: beatID,
            mode: mode,
            party: party,
            flags: flags,
            notes: stickyNotes,
            battle: battle,
            lastBattle: lastBattle,
            safety: safety,
            sessions: sessions,
            sceneNotes: sceneNotes,
            prepChecks: prepChecks,
            pinnedReferenceIDs: pinnedReferenceIDs,
            annotations: annotations,
            customBeats: customBeats,
            customMapPins: customMapPins,
            customNPCs: customNPCs,
            customMonsters: customMonsters,
            encounterAdjustments: encounterAdjustments,
            monsterOverrides: monsterOverrides
        )
    }

    public func apply(_ snapshot: RunStateSnapshot) {
        name = snapshot.name
        contentVersion = snapshot.contentVersion
        sceneID = snapshot.sceneID
        beatID = snapshot.beatID
        mode = snapshot.mode
        party = snapshot.party
        flags = snapshot.flags
        stickyNotes = snapshot.notes
        battle = snapshot.battle
        lastBattle = snapshot.lastBattle
        safety = snapshot.safety
        sessions = snapshot.sessions ?? []
        sceneNotes = snapshot.sceneNotes ?? [:]
        prepChecks = snapshot.prepChecks ?? []
        pinnedReferenceIDs = snapshot.pinnedReferenceIDs ?? []
        annotations = snapshot.annotations ?? []
        customBeats = snapshot.customBeats ?? []
        customMapPins = snapshot.customMapPins ?? []
        customNPCs = snapshot.customNPCs ?? []
        customMonsters = snapshot.customMonsters ?? []
        encounterAdjustments = snapshot.encounterAdjustments ?? []
        monsterOverrides = snapshot.monsterOverrides ?? []
    }

    private static func encode<T: Encodable>(_ value: T) -> Data {
        (try? JSONEncoder().encode(value)) ?? Data()
    }

    private static func encodeOptional<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? JSONDecoder().decode(type, from: data)
    }
}
