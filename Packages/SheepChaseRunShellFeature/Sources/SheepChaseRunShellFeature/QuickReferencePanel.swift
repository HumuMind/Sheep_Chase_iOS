import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

private enum QuickReferenceKind: String, CaseIterable, Identifiable {
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

private struct QuickReferenceEntry: Identifiable {
    let kind: QuickReferenceKind
    let itemID: String
    let title: String
    let subtitle: String?

    var id: String { "\(kind.rawValue):\(itemID)" }
}

private struct QuickReferenceSelection: Identifiable {
    let kind: QuickReferenceKind
    let itemID: String
    var id: String { "\(kind.rawValue):\(itemID)" }
}

public struct QuickReferencePanel: View {
    public init(run: RunRecord) {
        self.run = run
    }

    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @State private var isExpanded = true
    @State private var expandedKinds: Set<QuickReferenceKind> = [.npc]
    @State private var selection: QuickReferenceSelection?

    private var allEntries: [QuickReferenceEntry] {
        QuickReferenceKind.allCases.flatMap(entries(for:))
    }

    private var pinnedEntries: [QuickReferenceEntry] {
        run.pinnedReferenceIDs.compactMap { id in
            allEntries.first { $0.id == id }
        }
    }

    public var body: some View {
        Group {
            if isExpanded {
                expandedPanel
            } else {
                collapsedButton
            }
        }
        .sheet(item: $selection) { selection in
            detail(for: selection)
                .environment(store)
        }
    }

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "book.pages")
                    .foregroundStyle(Theme.red)
                Text("速查")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { isExpanded = false }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("收起速查")
                .accessibilityIdentifier("quick-reference-collapse")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            Divider().opacity(0.5)

            pinnedSection

            Divider().opacity(0.5)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(QuickReferenceKind.allCases) { kind in
                        category(kind)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 250)
        }
        .frame(width: 310)
        .frame(maxHeight: 360)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 7)
        .accessibilityIdentifier("quick-reference-panel")
    }

    private var collapsedButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { isExpanded = true }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "book.pages")
                Text("速查")
                if !pinnedEntries.isEmpty {
                    Text("\(pinnedEntries.count)")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Theme.red.opacity(0.12), in: Capsule())
                }
            }
            .font(.callout.weight(.medium))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quick-reference-open")
    }

    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("已钉住")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.red)
                Text("\(pinnedEntries.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if pinnedEntries.isEmpty {
                Text("钉住标签后会一直显示在这里")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(pinnedEntries) { entry in
                            pinnedTag(entry)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private func category(_ kind: QuickReferenceKind) -> some View {
        let entries = entries(for: kind)
        return DisclosureGroup(
            isExpanded: Binding(
                get: { expandedKinds.contains(kind) },
                set: { expanded in
                    if expanded { expandedKinds.insert(kind) } else { expandedKinds.remove(kind) }
                }
            )
        ) {
            if entries.isEmpty {
                Text("暂无内容")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(entries) { entry in
                            tag(entry)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Label(kind.title, systemImage: kind.icon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(entries.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 3)
        }
        .tint(Theme.red)
    }

    private func tag(_ entry: QuickReferenceEntry) -> some View {
        let pinned = run.pinnedReferenceIDs.contains(entry.id)
        return HStack(spacing: 0) {
            Button {
                selection = QuickReferenceSelection(kind: entry.kind, itemID: entry.itemID)
            } label: {
                Text(entry.title)
                    .font(.caption)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("qr-tag-\(entry.id)")

            Button {
                store.togglePinnedReference(entry.id, in: run)
            } label: {
                Image(systemName: pinned ? "pin.fill" : "pin")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(pinned ? Theme.red : .secondary)
                    .padding(.leading, 4)
                    .padding(.vertical, 5)
                    .padding(.trailing, 6)
            }
            .buttonStyle(.plain)
            .help(pinned ? "取消钉住" : "钉住")
            .accessibilityLabel(pinned ? "取消钉住\(entry.title)" : "钉住\(entry.title)")
            .accessibilityIdentifier("qr-pin-\(entry.id)")
        }
        .padding(.leading, 7)
        .background(
            Capsule().fill(pinned ? Theme.red.opacity(0.10) : Theme.paperDeep.opacity(0.65))
        )
        .overlay(
            Capsule().stroke(pinned ? Theme.red.opacity(0.35) : Theme.line.opacity(0.7), lineWidth: 0.7)
        )
    }

    private func pinnedTag(_ entry: QuickReferenceEntry) -> some View {
        HStack(spacing: 0) {
            Button {
                selection = QuickReferenceSelection(kind: entry.kind, itemID: entry.itemID)
            } label: {
                Text(entry.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("qr-pinned-\(entry.id)")

            Button {
                store.togglePinnedReference(entry.id, in: run)
            } label: {
                Image(systemName: "pin.slash")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
                    .padding(.vertical, 4)
                    .padding(.trailing, 6)
            }
            .buttonStyle(.plain)
            .help("取消钉住")
            .accessibilityLabel("取消钉住\(entry.title)")
            .accessibilityIdentifier("qr-unpin-\(entry.id)")
        }
        .padding(.leading, 7)
        .background(Capsule().fill(Theme.red.opacity(0.10)))
        .overlay(Capsule().stroke(Theme.red.opacity(0.28), lineWidth: 0.7))
    }

    private func entries(for kind: QuickReferenceKind) -> [QuickReferenceEntry] {
        switch kind {
        case .npc:
            return store.npcs.map {
                QuickReferenceEntry(kind: kind, itemID: $0.id, title: $0.name, subtitle: $0.role)
            }
        case .monster:
            return store.orderedBattleMonsters.map {
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

    @ViewBuilder
    private func detail(for selection: QuickReferenceSelection) -> some View {
        switch selection.kind {
        case .npc:
            if let npc = store.npc(id: selection.itemID) {
                NPCSheetView(npc: npc)
            }
        case .monster:
            if let monster = store.monster(id: selection.itemID) {
                MonsterSheetView(monster: monster)
            }
        case .item:
            if let item = store.item(id: selection.itemID) {
                ItemSheetView(item: item)
            }
        case .spell:
            if let spell = store.spell(id: selection.itemID) {
                SpellSheetView(spell: spell)
            }
        case .rule:
            if let rule = store.rule(id: selection.itemID) {
                RuleSheetView(rule: rule)
            }
        }
    }
}
