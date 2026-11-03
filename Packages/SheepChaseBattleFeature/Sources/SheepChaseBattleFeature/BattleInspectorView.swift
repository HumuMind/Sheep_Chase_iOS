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
    @State private var infoCombatant: BattleCombatant?

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("战斗")
                    .bookUI(13, weight: .semibold)
                Spacer()
                Text(battleSubtitle)
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }

            if let battle {
                switch battle.phase {
                case .select:
                    Text("在中间逐个选择玩家、添加怪物；准备好后填写先攻。")
                        .bookUI(12)
                        .foregroundStyle(.secondary)
                    Text(store.suggestedEncounter(for: run))
                        .bookUI(12)
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
                        .bookUI(12)
                        .foregroundStyle(.secondary)
                    ForEach(run.party.filter { battle.selectedPlayerIDs.contains($0.id) }) { member in
                        HStack {
                            Text(member.name)
                            Spacer()
                            Text(battle.playerInitiatives[member.id.uuidString].map(String.init) ?? "—")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .bookUI(12)
                    }
                    ForEach(battle.monsters) { monster in
                        HStack {
                            Text(monster.name)
                            Spacer()
                            Text(monster.initiative.map(String.init) ?? "—")
                                .monospacedDigit()
                                .foregroundStyle(Theme.green)
                        }
                        .bookUI(12)
                    }
                    ForEach(battle.allies ?? []) { ally in
                        HStack {
                            Text(ally.name + "（NPC）")
                            Spacer()
                            Text(ally.initiative.map(String.init) ?? "—")
                                .monospacedDigit()
                                .foregroundStyle(Theme.green)
                        }
                        .bookUI(12)
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
                    .bookUI(12)

                case .active:
                    ForEach(battle.combatants) { combatant in
                        HStack(spacing: 4) {
                            Button {
                                store.selectCombatant(combatant.id, in: run)
                            } label: {
                                HStack(spacing: 6) {
                                    Text("\(combatant.initiative)")
                                        .bookUI(11, monospaced: true)
                                        .frame(width: 22, alignment: .trailing)
                                        .foregroundStyle(combatant.id == battle.activeID ? Theme.red : .secondary)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(combatant.name)
                                            .bookUI(12, weight: combatant.id == battle.activeID ? .semibold : .regular)
                                        Text("\(combatant.kind == .player ? "玩家" : (combatant.kind == .npc ? "NPC" : "怪物")) · AC \(combatant.ac)")
                                            .bookUI(10)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(combatant.hp)/\(combatant.maxHP)")
                                        .bookUI(11, monospaced: true)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                infoCombatant = combatant
                            } label: {
                                Text("信息")
                                    .bookUI(10, weight: .medium)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(
                                        (combatant.id == battle.activeID ? Theme.red : Theme.inkSoft).opacity(0.08),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(combatant.id == battle.activeID ? Theme.red : Theme.inkSoft)
                            .accessibilityLabel("查看\(combatant.name)信息")
                            .help("查看\(combatant.name)的信息")
                        }
                        .padding(.vertical, 3)
                        .padding(.horizontal, 4)
                        .background(combatant.id == battle.activeID ? Theme.red.opacity(0.07) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
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
                    .bookUI(12)
                    .foregroundStyle(.secondary)
                Button("开始战斗筹备") {
                    store.openBattleSetup(for: run)
                }
                .buttonStyle(.bordered)
            }
        }
        .sheet(item: $infoCombatant) { combatant in
            CombatantInfoSheet(
                run: run,
                combatant: combatant,
                monster: monster(for: combatant),
                member: member(for: combatant),
                ally: ally(for: combatant)
            )
            .environment(store)
        }
    }

    private func monster(for combatant: BattleCombatant) -> ContentPack.Monster? {
        if let baseID = combatant.baseID, let monster = store.monster(id: baseID, in: run) {
            return monster
        }
        if let baseID = run.battle?.monsters.first(where: { $0.id == combatant.id })?.baseID {
            return store.monster(id: baseID, in: run)
        }
        return nil
    }

    private func member(for combatant: BattleCombatant) -> PartyMember? {
        run.party.first { $0.id == combatant.id }
    }

    private func ally(for combatant: BattleCombatant) -> BattleAlly? {
        run.battle?.allies?.first { $0.id == combatant.id }
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
