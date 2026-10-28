import SwiftUI

struct BattleSelectView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    private var battle: BattleState { run.battle ?? BattleState() }
    private var selectedPlayers: [PartyMember] {
        run.party.filter { battle.selectedPlayerIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("战斗筹备")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("先选人，再填先攻")
                            .font(.largeTitle.weight(.semibold))
                        Text("不是所有玩家都会参战，怪物数量也会随人数和等级变化。这里只给建议，不会自动加入。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("下一步：填写先攻") {
                        store.goToInitiative(in: run)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                    .disabled(battle.totalParticipants == 0)
                }

                BattleStepsView(phase: .select)

                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(run.party) { member in
                            PlayerSelectionRow(
                                member: member,
                                selected: battle.selectedPlayerIDs.contains(member.id)
                            ) {
                                store.toggleBattlePlayer(member, in: run)
                            }
                            if member.id != run.party.last?.id { Divider() }
                        }
                        if run.party.isEmpty {
                            Text("队伍为空。先到「队伍」页签添加玩家。")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.vertical, 2)
                } label: {
                    HStack {
                        Text("参战玩家").font(.headline)
                        Spacer()
                        Text("\(selectedPlayers.count) / \(run.party.count)").font(.caption).foregroundStyle(.secondary)
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(store.orderedBattleMonsters) { monster in
                                Button("＋ \(monster.name)") {
                                    store.addBattleMonster(monster, in: run)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        if battle.monsters.isEmpty {
                            Text("还没有添加怪物。逐个添加古兹、狼或棕熊。")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), alignment: .leading)], alignment: .leading, spacing: 5) {
                                ForEach(battle.monsters) { monster in
                                    HStack(spacing: 4) {
                                        Text(monster.name)
                                        Button {
                                            store.removeBattleMonster(monster.id, in: run)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 7, weight: .semibold))
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.secondary)
                                    }
                                    .font(.callout)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                } label: {
                    HStack {
                        Text("参战怪物").font(.headline)
                        Spacer()
                        Text("\(battle.monsters.count)").font(.caption).foregroundStyle(.secondary)
                    }
                }

                GroupBox("建议组合") {
                    Text(store.suggestedEncounter(for: run))
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 3)
                }

                HStack(spacing: 8) {
                    Button("下一步：填写先攻") {
                        store.goToInitiative(in: run)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                    .disabled(battle.totalParticipants == 0)

                    Button("清空参战者") {
                        store.clearBattleDraft(in: run)
                    }
                    .buttonStyle(.bordered)
                    .disabled(battle.totalParticipants == 0)

                    Spacer()
                    Text("玩家逐个加入，怪物逐个添加")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: 760, alignment: .leading)
            .readingPage()
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
