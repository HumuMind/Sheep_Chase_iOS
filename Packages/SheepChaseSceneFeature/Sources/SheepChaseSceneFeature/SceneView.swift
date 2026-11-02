import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

public struct SceneDetailView: View {
    public init(
        run: RunRecord,
        onOpenNPC: @escaping (String) -> Void = { _ in },
        onOpenHandout: @escaping (String) -> Void = { _ in },
        onOpenItem: @escaping (String) -> Void = { _ in },
        onOpenRule: @escaping (String) -> Void = { _ in },
        onOpenSpell: @escaping (String) -> Void = { _ in },
        onOpenMonster: @escaping (String) -> Void = { _ in },
        onOpenGuide: (() -> Void)? = nil
    ) {
        self.run = run
        self.onOpenNPC = onOpenNPC
        self.onOpenHandout = onOpenHandout
        self.onOpenItem = onOpenItem
        self.onOpenRule = onOpenRule
        self.onOpenSpell = onOpenSpell
        self.onOpenMonster = onOpenMonster
        self.onOpenGuide = onOpenGuide
    }

    @Environment(RunStore.self) var store
    @Bindable var run: RunRecord
    @State var showSource = false
    @State var showCustomBeat = false
    @State var editingEncounter: ContentPack.Encounter?
    var onOpenNPC: (String) -> Void = { _ in }
    var onOpenHandout: (String) -> Void = { _ in }
    var onOpenItem: (String) -> Void = { _ in }
    var onOpenRule: (String) -> Void = { _ in }
    var onOpenSpell: (String) -> Void = { _ in }
    var onOpenMonster: (String) -> Void = { _ in }
    var onOpenGuide: (() -> Void)?

    var scene: ContentPack.AdventureScene {
        store.currentScene(for: run)
    }

    private var sceneNoteBinding: Binding<String> {
        Binding(
            get: { store.sceneNote(for: scene.id, in: run) },
            set: { store.updateSceneNote($0, sceneID: scene.id, in: run) }
        )
    }

    var encounters: [ContentPack.Encounter] {
        (scene.encounterIds ?? []).compactMap { store.encounter(id: $0) }
    }

    var displayBeats: [SceneBeatItem] {
        scene.beats.map(SceneBeatItem.init(content:))
            + store.customBeats(for: scene.id, in: run).map(SceneBeatItem.init(custom:))
    }

    private var readAloudAnnotations: [DMAnnotation] {
        store.annotations(kind: .readAloud, targetID: scene.id, in: run)
    }

    private var sceneAnnotations: [DMAnnotation] {
        store.annotations(kind: .scene, targetID: scene.id, in: run)
    }

    private var displayedReadAloud: String? {
        let replacements = readAloudAnnotations.filter { $0.mode == .replace }.map(\.text)
        if !replacements.isEmpty {
            return replacements.joined(separator: "\n\n")
        }
        return scene.readAloud
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let onOpenGuide {
                    Button(action: onOpenGuide) {
                        HStack(spacing: 9) {
                            Image(systemName: "book.closed")
                                .foregroundStyle(Theme.red)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("DM 导读")
                                    .bookUI(13, weight: .semibold)
                                    .foregroundStyle(Theme.ink)
                                Text("摘要 · 引钩 · 背景 · 主持建议")
                                    .bookUI(10)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("开团前必读")
                                .bookUI(10, weight: .medium)
                                .foregroundStyle(Theme.red)
                            Image(systemName: "chevron.right")
                                .bookUI(10)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Theme.card, in: RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Theme.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("dm-guide-scene-banner")
                }

                header

                if let readAloud = displayedReadAloud {
                    GroupBox("朗读 / 描述") {
                        Text(readAloud.singleLineSpaced)
                            .bookUI(13)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                }

                GroupBox("DM 改动") {
                    VStack(alignment: .leading, spacing: 8) {
                        DMAnnotationEditor(
                            subject: "朗读 / 描述",
                            targetKind: .readAloud,
                            targetID: scene.id,
                            annotations: readAloudAnnotations,
                            onChange: { updated in
                                store.replaceAnnotations(kind: .readAloud, targetID: scene.id, with: updated, in: run)
                            }
                        )
                        Divider()
                        DMAnnotationEditor(
                            subject: "场景正文",
                            targetKind: .scene,
                            targetID: scene.id,
                            annotations: sceneAnnotations,
                            onChange: { updated in
                                store.replaceAnnotations(kind: .scene, targetID: scene.id, with: updated, in: run)
                            }
                        )
                    }
                    .padding(.vertical, 3)
                }

                beats
                beatNavigation
                branches
                flags
                encounterBox

                if let notes = scene.dmNotes {
                    GroupBox("DM 备注") {
                        Text(notes.singleLineSpaced)
                            .bookUI(12)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                }

                if let fadeToBlack = scene.fadeToBlack {
                    GroupBox("淡出处理 / 安全替代") {
                        Text(fadeToBlack.singleLineSpaced)
                            .bookUI(12)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                }

                GroupBox("本场景备注") {
                    TextEditor(text: sceneNoteBinding)
                        .bookUI(12)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 72)
                        .overlay(alignment: .topLeading) {
                            if sceneNoteBinding.wrappedValue.isEmpty {
                                Text("记录本场景的临时裁定、NPC 反应、队伍选择或下次继续的位置……")
                                    .bookUI(12)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.vertical, 2)
                }
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
            .readingPage()
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .sheet(isPresented: $showSource) {
            SourceTextSheet(scene: scene)
        }
        .sheet(isPresented: $showCustomBeat) {
            CustomBeatSheet(scene: scene, run: run)
                .environment(store)
        }
        .sheet(item: $editingEncounter) { encounter in
            EncounterAdjustmentSheet(encounter: encounter, run: run)
                .environment(store)
        }
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-demoSource") {
                showSource = true
            }
            #endif
        }
    }
}
