import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

public struct BattleInspector: View {
    public init(run: RunRecord) {
        self.run = run
    }
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    private var battle: BattleState? { run.battle }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("战斗")
                    .font(.headline)
                Spacer()
                Text(battleSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let battle {
                switch battle.phase {
                case .select:
                    Text("在中间逐个选择玩家、添加怪物；准备好后填写先攻。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(store.suggestedEncounter(for: run))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                    Button("下一步：填写先攻") {
                        store.goToInitiative(in: run)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(battle.totalParticipants == 0)

                case .initiative:
                    Text("玩家自己掷，你只需填结果；怪物先攻已自动掷好。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    ForEach(run.party.filter { battle.selectedPlayerIDs.contains($0.id) }) { member in
                        HStack {
                            Text(member.name)
                            Spacer()
                            Text(battle.playerInitiatives[member.id.uuidString].map(String.init) ?? "—")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .font(.callout)
                    }
                    ForEach(battle.monsters) { monster in
                        HStack {
                            Text(monster.name)
                            Spacer()
                            Text(monster.initiative.map(String.init) ?? "—")
                                .monospacedDigit()
                                .foregroundStyle(Theme.green)
                        }
                        .font(.callout)
                    }
                    Button("开始战斗") {
                        store.startBattle(in: run)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(!store.battleReady(run))
                    Button("返回选择参战者") {
                        store.backToSelect(in: run)
                    }
                    .buttonStyle(.borderless)
                    .font(.callout)

                case .active:
                    ForEach(battle.combatants) { combatant in
                        Button {
                            store.selectCombatant(combatant.id, in: run)
                        } label: {
                            HStack(spacing: 6) {
                                Text("\(combatant.initiative)")
                                    .font(.caption.monospacedDigit())
                                    .frame(width: 22, alignment: .trailing)
                                    .foregroundStyle(combatant.id == battle.activeID ? Theme.red : .secondary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(combatant.name)
                                        .font(.callout.weight(combatant.id == battle.activeID ? .semibold : .regular))
                                    Text("\(combatant.kind == .player ? "玩家" : "怪物") · AC \(combatant.ac)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(combatant.hp)/\(combatant.maxHP)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 4)
                            .background(combatant.id == battle.activeID ? Theme.red.opacity(0.07) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                        }
                        .buttonStyle(.plain)
                    }

                    Button("撤销上一步") {
                        store.undoBattle(in: run)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .disabled(battle.undo == nil)

                    Button("下一回合") {
                        store.nextTurn(in: run)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                    .frame(maxWidth: .infinity)

                    Button("结束战斗") {
                        store.endBattle(in: run)
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            } else {
                Text("尚未开始战斗。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("开始战斗筹备") {
                    store.openBattleSetup(for: run)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var battleSubtitle: String {
        guard let battle else { return "未开始" }
        switch battle.phase {
        case .select: return "选择参战者"
        case .initiative: return "填写先攻"
        case .active: return "第 \(battle.round) 轮"
        }
    }
}
