import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
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
                            .bookUI(11)
                            .foregroundStyle(.secondary)
                        Text("先选人，再填先攻")
                            .bookUI(28, weight: .semibold)
                        Text("选择玩家、怪物和特殊 NPC 盟友；不是所有玩家都会参战。这里只给建议，不会自动加入。")
                            .bookUI(12)
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
                                .bookUI(12)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                    .padding(.vertical, 2)
                } label: {
                    HStack {
                        Text("参战玩家").bookUI(13, weight: .semibold)
                        Spacer()
                        Text("\(selectedPlayers.count) / \(run.party.count)").bookUI(11).foregroundStyle(.secondary)
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(store.orderedBattleMonsters(in: run)) { monster in
                                Button("＋ \(monster.name)") {
                                    store.addBattleMonster(monster, in: run)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        if battle.monsters.isEmpty {
                            Text("还没有添加怪物。逐个添加古兹、狼或棕熊。")
                                .bookUI(12)
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
                                    .bookUI(12)
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
                        Text("参战怪物").bookUI(13, weight: .semibold)
                        Spacer()
                        Text("\(battle.monsters.count)").bookUI(11).foregroundStyle(.secondary)
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(battle.allies ?? []) { ally in
                            HStack(spacing: 5) {
                                Text(ally.name)
                                Text("NPC")
                                    .bookUI(9)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    store.removeBattleAlly(ally.id, in: run)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 7, weight: .semibold))
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                            .bookUI(12)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                        }

                        Button("＋ 范席尔（绵羊）") {
                            store.addBattleAlly(in: run)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled((battle.allies ?? []).contains { $0.baseID == "finethir-sheep" })

                        if (battle.allies ?? []).isEmpty {
                            Text("特殊 NPC 可以作为盟友参战，例如被变成绵羊的范席尔。")
                                .bookUI(11)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } label: {
                    HStack {
                        Text("参战 NPC / 盟友").bookUI(13, weight: .semibold)
                        Spacer()
                        Text("\(battle.allies?.count ?? 0)").bookUI(11).foregroundStyle(.secondary)
                    }
                }

                GroupBox("建议组合") {
                    Text(store.suggestedEncounter(for: run))
                        .bookUI(12)
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
                    Text("玩家、怪物和 NPC 盟友逐个加入")
                        .bookUI(11)
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
