import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

public struct QuickReferencePanel: View {
    public init(run: RunRecord) {
        self.run = run
    }
    @Environment(RunStore.self) var store
    @Bindable var run: RunRecord
    @AppStorage("quickReference.expanded") private var isExpanded = true
    @State private var expandedKinds: Set<QuickReferenceKind> = [.npc]
    @State private var selection: QuickReferenceSelection?
    @State var showAddNPC = false
    @State var showAddMonster = false
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
        .sheet(isPresented: $showAddNPC) {
            CustomNPCSheet(run: run)
                .environment(store)
        }
        .sheet(isPresented: $showAddMonster) {
            CustomMonsterSheet(run: run)
                .environment(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleQuickReferencePanel)) { _ in
            withAnimation(.easeInOut(duration: 0.16)) { isExpanded.toggle() }
        }
        .task {
            #if DEBUG
            if DemoLaunch.resetsQuickReference { isExpanded = true }
            if DemoLaunch.showsCustomNPCSheet { showAddNPC = true }
            #endif
        }
    }
    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "book.pages")
                    .foregroundStyle(Theme.red)
                Text("速查")
                    .bookUI(13, weight: .semibold)
                    .foregroundStyle(Theme.ink)
                    .help("速查面板（⌘R）")
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { isExpanded = false }
                } label: {
                    Label("收起", systemImage: "chevron.down")
                        .bookUI(10, weight: .medium)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
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
                        .bookUI(10, weight: .semibold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Theme.red.opacity(0.12), in: Capsule())
                }
            }
            .bookUI(12, weight: .medium)
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
        .help("速查面板（⌘R）")
    }
    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("已钉住")
                    .bookUI(10, weight: .semibold)
                    .foregroundStyle(Theme.red)
                Text("\(pinnedEntries.count)")
                    .bookUI(10)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if pinnedEntries.isEmpty {
                Text("右键或长按标签可钉住，钉住后会一直显示在这里")
                    .bookUI(10)
                    .foregroundStyle(.tertiary)
            } else {
                pinnedTagRows(pinnedEntries)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
    private func category(_ kind: QuickReferenceKind) -> some View {
        let entries = entries(for: kind)
        let expanded = expandedKinds.contains(kind)
        return VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(.easeInOut(duration: 0.12)) {
                    if expanded {
                        expandedKinds.remove(kind)
                    } else {
                        expandedKinds.insert(kind)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Label(kind.title, systemImage: kind.icon)
                        .bookUI(11, weight: .medium)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(entries.count)")
                        .bookUI(10)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(kind.title)，\(expanded ? "收起" : "展开")")
            .accessibilityIdentifier("qr-category-\(kind.rawValue)")
            if expanded {
                if entries.isEmpty {
                    Text("暂无内容")
                        .bookUI(10)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                } else {
                    tagRows(entries)
                        .padding(.vertical, 3)
                    if kind == .npc { customNPCButton }
                    if kind == .monster { customMonsterButton }
                }
            }
        }
    }
    private func tagRows(_ entries: [QuickReferenceEntry]) -> some View {
        VStack(spacing: 3) {
            ForEach(groupedRows(entries).indices, id: \.self) { index in
                HStack(spacing: 4) {
                    ForEach(groupedRows(entries)[index]) { entry in
                        tag(entry)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
    private func pinnedTagRows(_ entries: [QuickReferenceEntry]) -> some View {
        VStack(spacing: 3) {
            ForEach(groupedRows(entries).indices, id: \.self) { index in
                HStack(spacing: 4) {
                    ForEach(groupedRows(entries)[index]) { entry in
                        pinnedTag(entry)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
    private func groupedRows(_ entries: [QuickReferenceEntry]) -> [[QuickReferenceEntry]] {
        var rows: [[QuickReferenceEntry]] = []
        var current: [QuickReferenceEntry] = []
        var currentWidth: CGFloat = 0
        let maxWidth: CGFloat = 286
        for entry in entries {
            let width = estimatedTagWidth(entry)
            let spacing: CGFloat = current.isEmpty ? 0 : 4
            if !current.isEmpty, currentWidth + spacing + width > maxWidth {
                rows.append(current)
                current = []
                currentWidth = 0
            }
            currentWidth += (current.isEmpty ? 0 : 4) + width
            current.append(entry)
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
    private func estimatedTagWidth(_ entry: QuickReferenceEntry) -> CGFloat {
        let wide = entry.title.unicodeScalars.filter { $0.value > 0x2E80 }.count
        let narrow = entry.title.count - wide
        return CGFloat(wide) * 13 + CGFloat(narrow) * 7 + 24
    }
    private func tag(_ entry: QuickReferenceEntry) -> some View {
        let pinned = run.pinnedReferenceIDs.contains(entry.id)
        return Text(entry.title)
            .bookUI(11)
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(pinned ? Theme.red.opacity(0.10) : Theme.paperDeep.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(pinned ? Theme.red.opacity(0.35) : Theme.line.opacity(0.65), lineWidth: 0.7)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                selection = QuickReferenceSelection(kind: entry.kind, itemID: entry.itemID)
            }
            .contextMenu {
                Button {
                    store.togglePinnedReference(entry.id, in: run)
                } label: {
                    Label(pinned ? "取消钉住" : "钉住", systemImage: pinned ? "pin.slash" : "pin")
                }
                if entry.itemID.hasPrefix("custom-npc-"),
                   let uuid = UUID(uuidString: String(entry.itemID.dropFirst("custom-npc-".count))) {
                    Button(role: .destructive) {
                        store.deleteCustomNPC(uuid, in: run)
                    } label: {
                        Label("删除自定义人物", systemImage: "trash")
                    }
                }
                if entry.itemID.hasPrefix("custom-monster-"),
                   let uuid = UUID(uuidString: String(entry.itemID.dropFirst("custom-monster-".count))) {
                    Button(role: .destructive) {
                        store.deleteCustomMonster(uuid, in: run)
                    } label: {
                        Label("删除自定义怪物", systemImage: "trash")
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.title)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("qr-tag-\(entry.id)")
    }
    private func pinnedTag(_ entry: QuickReferenceEntry) -> some View {
        Text(entry.title)
            .bookUI(10, weight: .medium)
            .foregroundStyle(Theme.ink)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Theme.red.opacity(0.10)))
            .overlay(Capsule().stroke(Theme.red.opacity(0.28), lineWidth: 0.7))
            .contentShape(Rectangle())
            .onTapGesture {
                selection = QuickReferenceSelection(kind: entry.kind, itemID: entry.itemID)
            }
            .contextMenu {
                Button {
                    store.togglePinnedReference(entry.id, in: run)
                } label: {
                    Label("取消钉住", systemImage: "pin.slash")
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(entry.title)
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("qr-pinned-\(entry.id)")
    }
    @ViewBuilder
    private func detail(for selection: QuickReferenceSelection) -> some View {
        switch selection.kind {
        case .npc:
            if let npc = store.npc(id: selection.itemID, in: run) {
                NPCSheetView(
                    npc: npc,
                    annotations: store.annotations(kind: .npc, targetID: npc.id, in: run),
                    onAnnotationChange: { updated in
                        store.replaceAnnotations(kind: .npc, targetID: npc.id, with: updated, in: run)
                    }
                )
            }
        case .monster:
            if let monster = store.monster(id: selection.itemID, in: run) {
                MonsterSheetView(
                    monster: monster,
                    annotations: store.annotations(kind: .monster, targetID: monster.id, in: run),
                    onAnnotationChange: { updated in
                        store.replaceAnnotations(kind: .monster, targetID: monster.id, with: updated, in: run)
                    },
                    override: store.monsterOverride(for: monster.id, in: run),
                    onOverrideSave: { ac, hp, initMod, note in
                        store.setMonsterOverride(monsterID: monster.id, ac: ac, hp: hp, initiativeModifier: initMod, note: note, in: run)
                    },
                    onOverrideClear: {
                        store.clearMonsterOverride(monsterID: monster.id, in: run)
                    }
                )
            }
        case .item:
            if let item = store.item(id: selection.itemID) {
                ItemSheetView(
                    item: item,
                    annotations: store.annotations(kind: .item, targetID: item.id, in: run),
                    onAnnotationChange: { updated in
                        store.replaceAnnotations(kind: .item, targetID: item.id, with: updated, in: run)
                    }
                )
            }
        case .spell:
            if let spell = store.spell(id: selection.itemID) {
                SpellSheetView(
                    spell: spell,
                    annotations: store.annotations(kind: .spell, targetID: spell.id, in: run),
                    onAnnotationChange: { updated in
                        store.replaceAnnotations(kind: .spell, targetID: spell.id, with: updated, in: run)
                    }
                )
            }
        case .rule:
            if let rule = store.rule(id: selection.itemID) {
                RuleSheetView(
                    rule: rule,
                    annotations: store.annotations(kind: .rule, targetID: rule.id, in: run),
                    onAnnotationChange: { updated in
                        store.replaceAnnotations(kind: .rule, targetID: rule.id, with: updated, in: run)
                    }
                )
            }
        }
    }
}
