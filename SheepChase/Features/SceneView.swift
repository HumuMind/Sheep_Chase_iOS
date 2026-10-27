import SwiftUI

struct SceneDetailView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    private var scene: ContentPack.AdventureScene {
        store.currentScene(for: run)
    }

    private var encounter: ContentPack.Encounter? {
        scene.encounterIds?.first.flatMap { store.encounter(id: $0) }
    }

    var body: some View {
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
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var header: some View {
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
        }
        .padding(.bottom, 2)
    }

    private var beats: some View {
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
    }

    private var branches: some View {
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

    private var flags: some View {
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

    @ViewBuilder
    private var encounterBox: some View {
        if let encounter {
            GroupBox("遭遇 · \(encounter.title)") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(encounter.summary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
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

    private func beatTypeLabel(_ type: String) -> String {
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
