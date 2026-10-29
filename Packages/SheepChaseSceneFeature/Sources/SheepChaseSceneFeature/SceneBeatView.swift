import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

extension SceneDetailView {
    var beats: some View {
        VStack(alignment: .leading, spacing: 6) {
        GroupBox("节拍") {
            VStack(spacing: 0) {
                ForEach(displayBeats) { beat in
                    let selected = beat.id == run.beatID
                    Button {
                        store.selectBeatID(beat.id, in: run)
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: selected ? "circle.inset.filled" : "circle")
                                .font(.system(size: 11))
                                .foregroundStyle(selected ? Theme.red : .secondary)
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(beat.title)
                                        .font(.body.weight(.medium))
                                    Text(beatTypeLabel(beat.type))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text(beat.text.singleLineSpaced)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(2)
                                if let read = beat.readAloud {
                                    Text("“\(read.singleLineSpaced)”")
                                        .font(.callout)
                                        .italic()
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 1)
                                }
                                if let content = beat.content, let npcIDs = content.npcIds, !npcIDs.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(npcIDs, id: \.self) { npcID in
                                            if let npc = store.npc(id: npcID) {
                                                Button(npc.name) {
                                                    onOpenNPC(npcID)
                                                }
                                                .buttonStyle(.borderless)
                                                .font(.caption)
                                                .foregroundStyle(Theme.red)
                                            }
                                        }
                                    }
                                }
                                if let content = beat.content, let handoutIDs = content.handoutIds, !handoutIDs.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(handoutIDs, id: \.self) { handoutID in
                                            if let handout = store.handout(id: handoutID) {
                                                Button(handout.title) {
                                                    onOpenHandout(handoutID)
                                                }
                                                .buttonStyle(.borderless)
                                                .font(.caption)
                                                .foregroundStyle(Theme.red)
                                            }
                                        }
                                    }
                                }
                                if let content = beat.content, let itemIDs = content.itemIds, !itemIDs.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(itemIDs, id: \.self) { itemID in
                                            if let item = store.item(id: itemID) {
                                                Button(item.name) {
                                                    onOpenItem(itemID)
                                                }
                                                .buttonStyle(.borderless)
                                                .font(.caption)
                                                .foregroundStyle(Theme.red)
                                            }
                                        }
                                    }
                                }
                                if let content = beat.content, let ruleIDs = content.ruleIds, !ruleIDs.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(ruleIDs, id: \.self) { ruleID in
                                            if let rule = store.rule(id: ruleID) {
                                                Button(rule.term) { onOpenRule(ruleID) }
                                                    .buttonStyle(.borderless)
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.red)
                                            }
                                        }
                                    }
                                }
                                if let content = beat.content, let spellIDs = content.spellIds, !spellIDs.isEmpty {
                                    HStack(spacing: 5) {
                                        ForEach(spellIDs, id: \.self) { spellID in
                                            if let spell = store.spell(id: spellID) {
                                                Button(spell.name) { onOpenSpell(spellID) }
                                                    .buttonStyle(.borderless)
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.red)
                                            }
                                        }
                                    }
                                }
                                DMAnnotationEditor(
                                    subject: beat.title,
                                    annotation: store.annotation(kind: .beat, targetID: beat.id, in: run),
                                    onSave: { text, mode in
                                        store.setAnnotation(kind: .beat, targetID: beat.id, mode: mode, text: text, in: run)
                                    },
                                    onDelete: {
                                        store.removeAnnotation(kind: .beat, targetID: beat.id, in: run)
                                    }
                                )
                                .padding(.top, 1)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if let custom = beat.custom {
                            Button(role: .destructive) {
                                store.deleteCustomBeat(custom.id, in: run)
                            } label: {
                                Label("删除自定义节拍", systemImage: "trash")
                            }
                        }
                    }

                    if beat.id != displayBeats.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .overlay(alignment: .topTrailing) {
            if let dmText = scene.dmText, !dmText.isEmpty {
                Button {
                    showSource = true
                } label: {
                    Label("原文", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 7)
                .padding(.trailing, 12)
                .accessibilityIdentifier("scene-source-button")
            }
        }

        Button {
            showCustomBeat = true
        } label: {
            Label("＋ 自定义节拍", systemImage: "plus")
                .font(.callout)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(Theme.red)
        .padding(.leading, 2)
        }
    }

    var beatNavigation: some View {
        let index = displayBeats.firstIndex { $0.id == run.beatID } ?? 0
        return HStack(spacing: 8) {
            Button {
                let previous = max(0, index - 1)
                store.selectBeatID(displayBeats[previous].id, in: run)
            } label: {
                Label("上一拍", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(index == 0)

            Button {
                let next = min(displayBeats.count - 1, index + 1)
                store.selectBeatID(displayBeats[next].id, in: run)
            } label: {
                Label("下一拍", systemImage: "chevron.right")
            }
            .buttonStyle(.bordered)
            .disabled(index >= displayBeats.count - 1)

            Spacer()
            Text("第 \(index + 1) / \(displayBeats.count) 拍")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
