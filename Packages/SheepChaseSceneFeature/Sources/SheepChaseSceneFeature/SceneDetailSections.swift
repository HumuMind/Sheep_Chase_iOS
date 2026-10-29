import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

extension SceneDetailView {
    var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text("场景 \(scene.order) / \(store.scenes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.quaternary)
                Text("\(store.adventure.level.min)–\(store.adventure.level.max) 级")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(scene.title)
                .font(Theme.serif(32, weight: .semibold))
                .textSelection(.enabled)
            Text(scene.summary.singleLineSpaced)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(2)
                .textSelection(.enabled)

            HStack(spacing: 8) {
                if let npcIDs = scene.npcIds, !npcIDs.isEmpty {
                    ForEach(npcIDs, id: \.self) { npcID in
                        if let npc = store.npc(id: npcID) {
                            Button {
                                onOpenNPC(npcID)
                            } label: {
                                Label(npc.name, systemImage: "person.text.rectangle")
                                    .font(.callout)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                if let mapID = scene.mapIds?.first, let map = store.map(id: mapID) {
                    Button {
                        store.setMode(.map, in: run)
                    } label: {
                        Label(map.title, systemImage: "map")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if let handoutID = scene.handoutIds?.first, let handout = store.handout(id: handoutID) {
                    Button {
                        onOpenHandout(handoutID)
                    } label: {
                        Label(handout.title, systemImage: "doc.text")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if let itemID = scene.itemIds?.first, let item = store.item(id: itemID) {
                    Button {
                        onOpenItem(itemID)
                    } label: {
                        Label(item.name, systemImage: "wand.and.stars")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if !(scene.ruleIds ?? []).isEmpty || !(scene.spellIds ?? []).isEmpty {
                    Menu {
                        ForEach(scene.ruleIds ?? [], id: \.self) { ruleID in
                            if let rule = store.rule(id: ruleID) {
                                Button(rule.term) { onOpenRule(ruleID) }
                            }
                        }
                        ForEach(scene.spellIds ?? [], id: \.self) { spellID in
                            if let spell = store.spell(id: spellID) {
                                Button(spell.name) { onOpenSpell(spellID) }
                            }
                        }
                    } label: {
                        Label("本场速查", systemImage: "book.closed")
                            .font(.callout)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.bottom, 2)
    }

    var beats: some View {
        GroupBox("节拍") {
            VStack(spacing: 0) {
                ForEach(scene.beats) { beat in
                    let selected = beat.id == run.beatID
                    Button {
                        store.selectBeat(beat, in: run)
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
                                if let npcIDs = beat.npcIds, !npcIDs.isEmpty {
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
                                if let handoutIDs = beat.handoutIds, !handoutIDs.isEmpty {
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
                                if let itemIDs = beat.itemIds, !itemIDs.isEmpty {
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
                                if let ruleIDs = beat.ruleIds, !ruleIDs.isEmpty {
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
                                if let spellIDs = beat.spellIds, !spellIDs.isEmpty {
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

                    if beat.id != scene.beats.last?.id {
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
    }

    var beatNavigation: some View {
        let index = scene.beats.firstIndex { $0.id == run.beatID } ?? 0
        return HStack(spacing: 8) {
            Button {
                let previous = max(0, index - 1)
                store.selectBeat(scene.beats[previous], in: run)
            } label: {
                Label("上一拍", systemImage: "chevron.left")
            }
            .buttonStyle(.bordered)
            .disabled(index == 0)

            Button {
                let next = min(scene.beats.count - 1, index + 1)
                store.selectBeat(scene.beats[next], in: run)
            } label: {
                Label("下一拍", systemImage: "chevron.right")
            }
            .buttonStyle(.bordered)
            .disabled(index >= scene.beats.count - 1)

            Spacer()
            Text("第 \(index + 1) / \(scene.beats.count) 拍")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    var branches: some View {
        GroupBox("如果玩家……") {
            VStack(spacing: 0) {
                ForEach(scene.branches ?? []) { branch in
                    let triggered = branch.requiresFlag.map { run.flags[$0] ?? false } ?? false
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(branch.label)
                                .font(.callout.weight(.medium))
                            if let flag = branch.requiresFlag {
                                Text(triggered ? "已触发" : "条件：\(store.flagLabel(flag))")
                                    .font(.caption2)
                                    .foregroundStyle(triggered ? Theme.green : .secondary)
                            }
                        }
                        Text(branch.text.singleLineSpaced)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 7)
                    if branch.id != scene.branches?.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    var flags: some View {
        GroupBox("本团状态") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading, spacing: 6) {
                ForEach(store.content.flags) { flag in
                    let on = run.flags[flag.id] ?? false
                    Button {
                        store.toggleFlag(flag.id, in: run)
                    } label: {
                        Label(flag.label, systemImage: on ? "checkmark.circle.fill" : "circle")
                            .font(.callout)
                            .foregroundStyle(on ? Theme.green : .secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.vertical, 4)
        }
    }

    var encounterBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(encounters) { encounter in
                GroupBox("遭遇 · \(encounter.title)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(encounter.summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        if let tactics = encounter.tactics, !tactics.isEmpty {
                            Text(tactics.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        HStack(spacing: 5) {
                            ForEach(encounter.combatants, id: \.monsterId) { combatant in
                                if let monster = store.monster(id: combatant.monsterId) {
                                    Button(monster.name) {
                                        onOpenMonster(monster.id)
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundStyle(Theme.red)
                                }
                            }
                        }
                        Text("参考组合；按队伍人数与等级在战斗筹备里逐个添加。")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        HStack {
                            Button {
                                store.openBattleSetup(for: run)
                            } label: {
                                Label(run.battle?.phase == .active ? "返回战斗" : "筹备战斗", systemImage: "shield.lefthalf.filled")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.red)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    func beatTypeLabel(_ type: String) -> String {
        switch type {
        case "event": "事件"
        case "decision": "决策"
        case "roleplay": "扮演"
        case "encounter": "遭遇"
        case "transition": "转场"
        default: "备注"
        }
    }
}
