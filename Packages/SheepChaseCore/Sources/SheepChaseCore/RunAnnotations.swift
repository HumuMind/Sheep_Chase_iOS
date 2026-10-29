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
