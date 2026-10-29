import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore

extension QuickReferencePanel {
    func entries(for kind: QuickReferenceKind) -> [QuickReferenceEntry] {
        switch kind {
        case .npc:
            let content = store.npcs.map {
                QuickReferenceEntry(kind: kind, itemID: $0.id, title: $0.name, subtitle: $0.role)
            }
            let custom = store.customNPCs(in: run).map {
                QuickReferenceEntry(kind: kind, itemID: "custom-npc-\($0.id.uuidString)", title: $0.name, subtitle: $0.role)
            }
            return content + custom
        case .monster:
            return store.orderedBattleMonsters(in: run).map {
                QuickReferenceEntry(kind: kind, itemID: $0.id, title: $0.name, subtitle: $0.type)
            }
        case .item:
            return store.items.map {
                QuickReferenceEntry(kind: kind, itemID: $0.id, title: $0.name, subtitle: $0.kind)
            }
        case .spell:
            return store.content.spells
                .sorted { ($0.level, $0.name) < ($1.level, $1.name) }
                .map {
                    QuickReferenceEntry(kind: kind, itemID: $0.id, title: $0.name, subtitle: "\($0.level) 环 · \($0.school)")
                }
        case .rule:
            return store.content.rules
                .sorted { ($0.category, $0.term) < ($1.category, $1.term) }
                .map {
                    QuickReferenceEntry(kind: kind, itemID: $0.id, title: $0.term, subtitle: $0.category)
                }
        }
    }
}
