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

    init(
        name: String,
        sceneID: String = "scene-1",
        beatID: String = "sheep-arrives"
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
