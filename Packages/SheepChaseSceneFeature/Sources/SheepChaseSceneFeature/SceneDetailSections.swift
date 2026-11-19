import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

extension SceneDetailView {
    var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text("场景 \(scene.order) / \(store.scenes.count)")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.quaternary)
                Text("\(store.adventure.level.min)–\(store.adventure.level.max) 级")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text(scene.title)
                .bookSerif(32, weight: .semibold)
                .textSelection(.enabled)
            Text(scene.summary.singleLineSpaced)
                .bookUI(13)
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
                                    .bookUI(12)
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
                            .bookUI(12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if let handoutID = scene.handoutIds?.first, let handout = store.handout(id: handoutID) {
                    Button {
                        onOpenHandout(handoutID)
                    } label: {
                        Label(handout.title, systemImage: "doc.text")
                            .bookUI(12)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                if let itemID = scene.itemIds?.first, let item = store.item(id: itemID) {
                    Button {
                        onOpenItem(itemID)
                    } label: {
                        Label(item.name, systemImage: "wand.and.stars")
                            .bookUI(12)
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
                            .bookUI(12)
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

    var branches: some View {
        GroupBox("如果玩家……") {
            VStack(spacing: 0) {
                ForEach(scene.branches ?? []) { branch in
                    let triggered = branch.requiresFlag.map { run.flags[$0] ?? false } ?? false
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(branch.label)
                                .bookUI(12, weight: .medium)
                            if let flag = branch.requiresFlag {
                                Text(triggered ? "已触发" : "条件：\(store.flagLabel(flag))")
                                    .bookUI(10)
                                    .foregroundStyle(triggered ? Theme.green : .secondary)
                            }
                        }
                        Text(branch.text.singleLineSpaced)
                            .bookUI(12)
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
                            .bookUI(12)
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
                            .bookUI(12)
                            .foregroundStyle(.secondary)
                        if let tactics = encounter.tactics, !tactics.isEmpty {
                            Text(tactics.joined(separator: " · "))
                                .bookUI(11)
                                .foregroundStyle(.tertiary)
                        }
                        HStack(spacing: 5) {
                            ForEach(encounter.combatants, id: \.monsterId) { combatant in
                                if let monster = store.monster(id: combatant.monsterId) {
                                    Button(monster.name) {
                                        onOpenMonster(monster.id)
                                    }
                                    .buttonStyle(.borderless)
                                    .bookUI(11)
                                    .foregroundStyle(Theme.red)
                                }
                            }
                        }
                        if let adjustment = store.encounterAdjustment(for: encounter.id, in: run) {
                            Text("DM 调整：")
                                .bookUI(11, weight: .semibold)
                                .foregroundStyle(Theme.gold)
                            ForEach(adjustment.combatants) { combatant in
                                if let monster = store.monster(id: combatant.monsterID, in: run) {
                                    Text("\(monster.name) × \(combatant.count)")
                                        .bookUI(11)
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                            if !adjustment.note.isEmpty {
                                Text(adjustment.note)
                                    .bookUI(11)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("参考组合；按队伍人数与等级在战斗筹备里逐个添加。")
                                .bookUI(11)
                                .foregroundStyle(.tertiary)
                        }
                        DMAnnotationEditor(
                            subject: encounter.title,
                            targetKind: .encounter,
                            targetID: encounter.id,
                            annotations: store.annotations(kind: .encounter, targetID: encounter.id, in: run),
                            onChange: { updated in
                                store.replaceAnnotations(kind: .encounter, targetID: encounter.id, with: updated, in: run)
                            }
                        )
                        HStack {
                            Button {
                                store.prepareEncounter(encounter.id, in: run)
                            } label: {
                                Label(run.battle?.phase == .active ? "返回战斗" : "按调整筹备", systemImage: "shield.lefthalf.filled")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.red)
                            Button {
                                editingEncounter = encounter
                            } label: {
                                Label("调整遭遇", systemImage: "slider.horizontal.3")
                            }
                            .buttonStyle(.bordered)
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
