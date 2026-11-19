import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct GlobalSearchResult: Identifiable, Hashable {
    let id: String
    let kind: String
    let title: String
    let subtitle: String
    let body: String
    let sceneID: String?
}

public struct GlobalSearchView: View {
    public init(run: RunRecord?) {
        self.run = run
    }
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord?

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var results: [GlobalSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)

        var results: [GlobalSearchResult] = []
        for scene in store.scenes {
            let haystack = [scene.title, scene.summary, scene.readAloud ?? "", scene.dmText ?? ""].joined(separator: " ")
            if haystack.localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(
                    id: "scene:\(scene.id)",
                    kind: "场景",
                    title: scene.title,
                    subtitle: "场景 \(scene.order) / \(store.scenes.count)",
                    body: [scene.summary, scene.readAloud ?? "", scene.dmText ?? ""].filter { !$0.isEmpty }.joined(separator: "\n\n"),
                    sceneID: scene.id
                ))
            }
        }
        for npc in store.npcs {
            let haystack = [npc.name, npc.role, npc.publicDescription, npc.dmDescription, npc.voice, npc.motivation, npc.knows.joined(separator: " "), npc.secrets.joined(separator: " ")].joined(separator: " ")
            if haystack.localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(
                    id: "npc:\(npc.id)",
                    kind: "NPC",
                    title: npc.name,
                    subtitle: npc.role,
                    body: [npc.publicDescription, "DM：" + npc.dmDescription, "语气：\(npc.voice)", "想要：\(npc.wants.joined(separator: "、"))", "秘密：\(npc.secrets.joined(separator: "、"))"].joined(separator: "\n\n"),
                    sceneID: nil
                ))
            }
        }
        for monster in store.content.monsters {
            let haystack = [monster.name, monster.type, monster.alignment, monster.tactics?.joined(separator: " ") ?? "", monster.actions.map { $0.name + " " + $0.text }.joined(separator: " ")].joined(separator: " ")
            if haystack.localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(
                    id: "monster:\(monster.id)",
                    kind: "怪物",
                    title: monster.name,
                    subtitle: "AC \(monster.ac.value) · HP \(monster.hp.average) · CR \(monster.challenge.rating)",
                    body: ([("\(monster.size)\(monster.type) · \(monster.alignment)")] + monster.actions.map { "\($0.name)：\($0.text)" }).joined(separator: "\n\n"),
                    sceneID: nil
                ))
            }
        }
        for encounter in store.content.encounters {
            let haystack = [encounter.title, encounter.summary, encounter.tactics?.joined(separator: " ") ?? "", encounter.terrain ?? ""].joined(separator: " ")
            if haystack.localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(
                    id: "encounter:\(encounter.id)",
                    kind: "遭遇",
                    title: encounter.title,
                    subtitle: encounter.difficulty ?? "遭遇参考",
                    body: [encounter.summary, encounter.tactics?.joined(separator: "\n") ?? "", encounter.terrain ?? ""].filter { !$0.isEmpty }.joined(separator: "\n\n"),
                    sceneID: nil
                ))
            }
        }
        for rule in store.content.rules {
            if [rule.term, rule.category, rule.summary, rule.aliases.joined(separator: " ")].joined(separator: " ").localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(id: "rule:\(rule.id)", kind: "规则", title: rule.term, subtitle: "\(rule.category) · \(rule.pageRef)", body: rule.summary, sceneID: nil))
            }
        }
        for spell in store.content.spells {
            if [spell.name, spell.school, spell.summary, spell.aliases.joined(separator: " ")].joined(separator: " ").localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(id: "spell:\(spell.id)", kind: "法术", title: spell.name, subtitle: "\(spell.level) 环 · \(spell.school)", body: spell.summary, sceneID: nil))
            }
        }
        for item in store.items {
            if [item.name, item.kind, item.summary].joined(separator: " ").localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(id: "item:\(item.id)", kind: "物品", title: item.name, subtitle: item.kind, body: item.summary, sceneID: nil))
            }
        }
        for handout in store.handouts {
            if [handout.title, handout.playerText, handout.dmText ?? ""].joined(separator: " ").localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(id: "handout:\(handout.id)", kind: "手牌", title: handout.title, subtitle: handout.kind, body: handout.playerText, sceneID: nil))
            }
        }
        for map in store.maps {
            if [map.title, map.pins.map { $0.label + " " + ($0.description ?? "") }.joined(separator: " ")].joined(separator: " ").localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(id: "map:\(map.id)", kind: "地图", title: map.title, subtitle: "\(map.pins.count) 个图钉", body: map.pins.map { "\($0.label)：\($0.description ?? "")" }.joined(separator: "\n"), sceneID: nil))
            }
        }
        if let run {
            for annotation in run.annotations where annotation.text.localizedCaseInsensitiveContains(needle) {
                results.append(GlobalSearchResult(
                    id: "annotation:\(annotation.id)",
                    kind: "DM 改动",
                    title: annotationTitle(annotation),
                    subtitle: annotation.targetKind.rawValue,
                    body: annotation.text,
                    sceneID: sceneID(for: annotation)
                ))
            }
        }
        return results
    }

    private func annotationTitle(_ annotation: DMAnnotation) -> String {
        switch annotation.targetKind {
        case .scene, .readAloud:
            return store.scene(id: annotation.targetID)?.title ?? annotation.targetID
        case .beat:
            for scene in store.scenes {
                if let beat = scene.beats.first(where: { $0.id == annotation.targetID }) {
                    return beat.title
                }
            }
            return annotation.targetID
        case .npc:
            return store.npc(id: annotation.targetID)?.name ?? annotation.targetID
        case .monster:
            return store.monster(id: annotation.targetID)?.name ?? annotation.targetID
        case .item:
            return store.item(id: annotation.targetID)?.name ?? annotation.targetID
        case .spell:
            return store.spell(id: annotation.targetID)?.name ?? annotation.targetID
        case .rule:
            return store.rule(id: annotation.targetID)?.term ?? annotation.targetID
        case .handout:
            return store.handout(id: annotation.targetID)?.title ?? annotation.targetID
        case .encounter:
            return store.encounter(id: annotation.targetID)?.title ?? annotation.targetID
        case .guide:
            return "DM 导读"
        }
    }

    private func sceneID(for annotation: DMAnnotation) -> String? {
        switch annotation.targetKind {
        case .scene, .readAloud:
            return annotation.targetID
        case .beat:
            return store.scenes.first { scene in
                scene.beats.contains { $0.id == annotation.targetID }
            }?.id
        default:
            return nil
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 7) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("搜索场景、NPC、怪物、规则、法术、DM 改动…", text: $query)
                        .textFieldStyle(.plain)
                        .focused($searchFocused)
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Theme.readingPaper, in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6).stroke(Theme.line, lineWidth: 1)
                )
                .padding(12)

                if query.isEmpty {
                    ContentUnavailableView(
                        "全局速查",
                        systemImage: "magnifyingglass",
                        description: Text("输入关键词；支持中文、英文别名与场景文本。⌘K 可随时打开。")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(results) { result in
                        NavigationLink(value: result) {
                            HStack(alignment: .top, spacing: 9) {
                                Text(result.kind)
                                    .bookUI(10, weight: .semibold)
                                    .foregroundStyle(Theme.red)
                                    .frame(width: 34, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.title)
                                        .bookUI(13, weight: .medium)
                                    Text(result.subtitle)
                                        .bookUI(11)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .listStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .background(Theme.readingPaper)
                }
            }
            .background(Theme.readingPaper)
            .environment(\.colorScheme, .light)
            .navigationTitle("全局速查")
            .compactNavigationTitle()
            .navigationDestination(for: GlobalSearchResult.self) { result in
                SearchResultDetail(result: result, run: run) {
                    if let sceneID = result.sceneID, let run, let scene = store.scene(id: sceneID) {
                        store.selectScene(scene, in: run)
                    }
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
        .onAppear { searchFocused = true }
    }
}

private struct SearchResultDetail: View {
    let result: GlobalSearchResult
    let run: RunRecord?
    let onOpenScene: () -> Void

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(result.kind)
                    .bookUI(11)
                    .foregroundStyle(.secondary)
                Text(result.title)
                    .bookUI(28, weight: .semibold)
                Text(result.subtitle)
                    .bookUI(12)
                    .foregroundStyle(.secondary)
                Text(result.body)
                    .bookUI(13)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                if result.sceneID != nil, run != nil {
                    Button("在当前开团打开这个场景") {
                        onOpenScene()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                }
            }
            .padding(24)
            .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
            .readingPage()
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Theme.readingPaper)
        .navigationTitle(result.title)
    }
}
