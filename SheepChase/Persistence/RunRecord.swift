import Foundation
import SwiftData

@Model
final class RunRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var sceneID: String
    var beatID: String
    var modeRaw: String
    var partyData: Data
    var flagsData: Data
    var notesData: Data
    var battleData: Data?
    var safetyData: Data?
    var sessionsData: Data?
    var checkpointsData: Data?
    var sceneNotesData: Data?
    var prepData: Data?
    var isArchived: Bool = false
    var contentVersion: String = ""

    init(
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
        self.safetyData = Self.encode(SafetyState())
        self.sessionsData = Self.encode([RunSession]())
        self.checkpointsData = Self.encode([RunCheckpoint]())
        self.sceneNotesData = Self.encode([String: String]())
        self.prepData = Self.encode([String]())
        self.isArchived = false
        self.contentVersion = contentVersion
    }

    var mode: RunMode {
        get { RunMode(rawValue: modeRaw) ?? .scene }
        set { modeRaw = newValue.rawValue }
    }

    var party: [PartyMember] {
        get { Self.decode([PartyMember].self, from: partyData) ?? [] }
        set { partyData = Self.encode(newValue) }
    }

    var flags: [String: Bool] {
        get { Self.decode([String: Bool].self, from: flagsData) ?? [:] }
        set { flagsData = Self.encode(newValue) }
    }

    var stickyNotes: [StickyNote] {
        get { Self.decode([StickyNote].self, from: notesData) ?? [] }
        set { notesData = Self.encode(newValue) }
    }

    var battle: BattleState? {
        get {
            guard let battleData else { return nil }
            return Self.decode(BattleState.self, from: battleData)
        }
        set {
            battleData = newValue.flatMap { Self.encodeOptional($0) }
        }
    }

    var safety: SafetyState {
        get {
            guard let safetyData else { return SafetyState() }
            return Self.decode(SafetyState.self, from: safetyData) ?? SafetyState()
        }
        set {
            safetyData = Self.encode(newValue)
        }
    }

    var sessions: [RunSession] {
        get {
            guard let sessionsData else { return [] }
            return Self.decode([RunSession].self, from: sessionsData) ?? []
        }
        set {
            sessionsData = Self.encode(newValue)
        }
    }

    var checkpoints: [RunCheckpoint] {
        get {
            guard let checkpointsData else { return [] }
            return Self.decode([RunCheckpoint].self, from: checkpointsData) ?? []
        }
        set {
            checkpointsData = Self.encode(newValue)
        }
    }

    var sceneNotes: [String: String] {
        get {
            guard let sceneNotesData else { return [:] }
            return Self.decode([String: String].self, from: sceneNotesData) ?? [:]
        }
        set {
            sceneNotesData = Self.encode(newValue)
        }
    }

    var prepChecks: [String] {
        get {
            guard let prepData else { return [] }
            return Self.decode([String].self, from: prepData) ?? []
        }
        set {
            prepData = Self.encode(newValue)
        }
    }

    var stateSnapshot: RunStateSnapshot {
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
            safety: safety,
            sessions: sessions,
            sceneNotes: sceneNotes,
            prepChecks: prepChecks
        )
    }

    func apply(_ snapshot: RunStateSnapshot) {
        name = snapshot.name
        contentVersion = snapshot.contentVersion
        sceneID = snapshot.sceneID
        beatID = snapshot.beatID
        mode = snapshot.mode
        party = snapshot.party
        flags = snapshot.flags
        stickyNotes = snapshot.notes
        battle = snapshot.battle
        safety = snapshot.safety
        sessions = snapshot.sessions
        sceneNotes = snapshot.sceneNotes ?? [:]
        prepChecks = snapshot.prepChecks ?? []
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
