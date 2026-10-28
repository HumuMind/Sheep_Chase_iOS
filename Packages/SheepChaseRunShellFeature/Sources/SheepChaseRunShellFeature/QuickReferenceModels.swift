import Foundation

enum QuickReferenceKind: String, CaseIterable, Identifiable {
    case npc
    case monster
    case item
    case spell
    case rule

    var id: String { rawValue }
    var title: String {
        switch self {
        case .npc: "人物"
        case .monster: "怪物"
        case .item: "物品"
        case .spell: "法术"
        case .rule: "规则"
        }
    }
    var icon: String {
        switch self {
        case .npc: "person.2"
        case .monster: "pawprint"
        case .item: "shippingbox"
        case .spell: "sparkles"
        case .rule: "text.book.closed"
        }
    }
}

struct QuickReferenceEntry: Identifiable {
    let kind: QuickReferenceKind
    let itemID: String
    let title: String
    let subtitle: String?

    var id: String { "\(kind.rawValue):\(itemID)" }
}

struct QuickReferenceSelection: Identifiable {
    let kind: QuickReferenceKind
    let itemID: String
    var id: String { "\(kind.rawValue):\(itemID)" }
}
