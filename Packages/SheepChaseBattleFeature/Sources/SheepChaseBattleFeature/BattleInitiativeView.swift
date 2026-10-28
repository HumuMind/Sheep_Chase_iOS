import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct BattleInitiativeView: View {
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
                        Text("战斗筹备 / 填写先攻")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("玩家自己掷，你来填")
                            .font(.largeTitle.weight(.semibold))
                        Text("玩家投 d20 + 先攻加值，把结果填进来；怪物先攻已由 App 自动掷好（d20 + 加值），不需要填写。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("开始战斗") {
                        store.startBattle(in: run)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                    .disabled(!store.battleReady(run))
                }

                BattleStepsView(phase: .initiative)

                GroupBox {
                    VStack(spacing: 0) {
                        ForEach(selectedPlayers) { member in
                            HStack(spacing: 10) {
                                Text(member.name)
                                    .font(.body.weight(.medium))
                                Text("玩家 · 先攻加值 \(signed(member.initMod))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                TextField("先攻", text: playerBinding(member))
                                    .textFieldStyle(.roundedBorder)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 64)
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }

                        ForEach(battle.monsters) { monster in
                            HStack(spacing: 10) {
                                Text(monster.name)
                                    .font(.body.weight(.medium))
                                Text("怪物 · 自动 d20 + 加值")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(monster.initiative.map(String.init) ?? "—")
                                    .font(.body.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(Theme.green)
                                    .frame(width: 64, height: 24)
                                    .background(Theme.green.opacity(0.07), in: RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                    .padding(.vertical, 2)
                } label: {
                    HStack {
                        Text("先攻记录").font(.headline)
                        Spacer()
                        Text("\(filledCount) / \(battle.totalParticipants)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Button("开始战斗") {
                        store.startBattle(in: run)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                    .disabled(!store.battleReady(run))

                    Button("返回选择参战者") {
                        store.backToSelect(in: run)
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                    Text("玩家先攻都填完后才能开始；怪物已自动掷好")
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

    private var filledCount: Int {
        selectedPlayers.compactMap { battle.playerInitiatives[$0.id.uuidString] }.count
            + battle.monsters.filter { $0.initiative != nil }.count
    }

    private func playerBinding(_ member: PartyMember) -> Binding<String> {
        Binding(
            get: {
                guard let value = run.battle?.playerInitiatives[member.id.uuidString] else { return "" }
                return String(value)
            },
            set: { value in
                store.setPlayerInitiative(value, memberID: member.id, in: run)
            }
        )
    }

    private func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
