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
        onOpenMonster: @escaping (String) -> Void = { _ in }
    ) {
        self.run = run
        self.onOpenNPC = onOpenNPC
        self.onOpenHandout = onOpenHandout
        self.onOpenItem = onOpenItem
        self.onOpenRule = onOpenRule
        self.onOpenSpell = onOpenSpell
        self.onOpenMonster = onOpenMonster
    }

    @Environment(RunStore.self) var store
    @Bindable var run: RunRecord
    var onOpenNPC: (String) -> Void = { _ in }
    var onOpenHandout: (String) -> Void = { _ in }
    var onOpenItem: (String) -> Void = { _ in }
    var onOpenRule: (String) -> Void = { _ in }
    var onOpenSpell: (String) -> Void = { _ in }
    var onOpenMonster: (String) -> Void = { _ in }

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

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let readAloud = scene.readAloud {
                    GroupBox("朗读 / 描述") {
                        Text(readAloud.singleLineSpaced)
                            .font(.body)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                }

                beats
                beatNavigation
                branches
                flags
                encounterBox

                if let notes = scene.dmNotes {
                    GroupBox("DM 备注") {
                        Text(notes.singleLineSpaced)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                }

                if let fadeToBlack = scene.fadeToBlack {
                    GroupBox("淡出处理 / 安全替代") {
                        Text(fadeToBlack.singleLineSpaced)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                }

                GroupBox("本场景备注") {
                    TextEditor(text: sceneNoteBinding)
                        .font(.callout)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 72)
                        .overlay(alignment: .topLeading) {
                            if sceneNoteBinding.wrappedValue.isEmpty {
                                Text("记录本场景的临时裁定、NPC 反应、队伍选择或下次继续的位置……")
                                    .font(.callout)
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
    }
}
