import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct BattleActiveView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    private var battle: BattleState? { run.battle }
    private var active: BattleCombatant? { store.activeCombatant(in: run) }
    private var activeMonster: ContentPack.Monster? {
        guard let active else { return nil }
        if let baseID = active.baseID, let monster = store.monster(id: baseID, in: run) {
            return monster
        }
        // Older battles created before combatants stored baseID: recover it
        // from the battle draft, whose monster IDs match the combatant IDs.
        if let baseID = run.battle?.monsters.first(where: { $0.id == active.id })?.baseID {
            return store.monster(id: baseID, in: run)
        }
        return nil
    }

    private var activeMember: PartyMember? {
        guard let active, active.kind == .player else { return nil }
        return run.party.first { $0.id == active.id }
    }

    private var activeAlly: BattleAlly? {
        guard let active, active.kind == .npc else { return nil }
        return run.battle?.allies?.first { $0.id == active.id }
    }

    @State private var showMultiDamage = false
    @State private var selectedRule: ContentPack.RuleCard?
    @State private var selectedSpell: ContentPack.SpellCard?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("战斗 · 第 \(battle?.round ?? 1) 轮")
                            .bookUI(11)
                            .foregroundStyle(.secondary)
                        Text(store.encounter(id: "guz-ambush")?.title ?? "战斗")
                            .bookUI(28, weight: .semibold)
                    }
                    Spacer()
                    if let battle, battle.phase == .active {
                        Button("撤销上一步") {
                            store.undoBattle(in: run)
                        }
                        .buttonStyle(.bordered)
                        .disabled(battle.undo == nil)
                        Button {
                            store.openDicePanel(subject: active?.name ?? "", logToBattle: true)
                        } label: {
                            Label("投掷", systemImage: "die.face.5")
                        }
                        .buttonStyle(.bordered)
                        Button("多目标伤害") {
                            showMultiDamage = true
                        }
                        .buttonStyle(.bordered)
                        Button("下一回合") {
                            store.nextTurn(in: run)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.red)
                        Button("结束战斗") {
                            store.endBattle(in: run)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if let active {
                    CombatantInfoView(
                        combatant: active,
                        monster: activeMonster,
                        member: activeMember,
                        ally: activeAlly,
                        onOpenRule: { ruleID in
                            if let rule = store.rule(id: ruleID) { selectedRule = rule }
                        },
                        onOpenSpell: { spellID in
                            if let spell = store.spell(id: spellID) { selectedSpell = spell }
                        }
                    )
                }

                if let active {
                    GroupBox("当前回合") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(active.name)
                                    .bookUI(19, weight: .semibold)
                                Text(active.kind == .player ? "玩家" : (active.kind == .npc ? "NPC" : "怪物"))
                                    .bookUI(11)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("AC \(active.ac)")
                                    .bookUI(12, monospaced: true)
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Text("HP")
                                        .bookUI(11)
                                        .foregroundStyle(.secondary)
                                    TextField("0", value: hpBinding(active), format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .bookUI(13, monospaced: true)
                                        .frame(width: 54)
                                        .selectAllOnFocus()
                                    Text("/ \(active.maxHP)")
                                        .bookUI(13, monospaced: true)
                                }
                                HStack(spacing: 4) {
                                    Text("临时")
                                        .bookUI(11)
                                        .foregroundStyle(.secondary)
                                    TextField("0", value: tempHPBinding(active), format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 46)
                                }
                                Text("先攻 \(active.initiative)")
                                    .bookUI(12)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                TextField("专注：例如加速术", text: concentrationBinding(active))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 180)
                            }

                            if let concentration = active.concentration, !concentration.isEmpty {
                                Text("专注中：\(concentration)。受到伤害时按专注规则进行体质豁免。")
                                    .bookUI(11)
                                    .foregroundStyle(Theme.red)
                            }

                            ProgressView(value: Double(active.hp), total: Double(max(active.maxHP, 1)))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("战斗笔记")
                                    .bookUI(10, weight: .semibold)
                                    .foregroundStyle(.secondary)
                                TextField("记录这个参与者的战斗状态、战术或临时裁定……", text: noteBinding(active), axis: .vertical)
                                    .textFieldStyle(.plain)
                                    .bookUI(11)
                                    .lineLimit(2...5)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 5)
                                    .background(Theme.paperDeep.opacity(0.22), in: RoundedRectangle(cornerRadius: 5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Theme.line.opacity(0.5), lineWidth: 1)
                                    )
                            }

                                .tint(active.hp <= active.maxHP / 4 ? Theme.redSoft : Theme.green)

                            HStack(spacing: 5) {
                                ForEach(["受擒", "倒地", "恐慌", "中毒"], id: \.self) { condition in
                                    let on = active.conditions.contains(condition)
                                    Button(condition) {
                                        store.toggleCondition(condition, in: run)
                                    }
                                    .buttonStyle(.plain)
                                    .bookUI(11)
                                    .foregroundStyle(on ? .white : .secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(on ? Theme.green : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(on ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 1)
                                    )
                                }

                                Menu {
                                    ForEach(extraConditions, id: \.self) { condition in
                                        Button {
                                            store.toggleCondition(condition, in: run)
                                        } label: {
                                            Label(
                                                active.conditions.contains(condition) ? "\(condition) ✓" : condition,
                                                systemImage: active.conditions.contains(condition) ? "checkmark.circle.fill" : "circle"
                                            )
                                        }
                                    }
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .bookUI(11)
                                }
                                .menuStyle(.borderlessButton)
                                .help("更多状态")
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    GroupBox("战斗日志") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array((battle?.log ?? []).prefix(9).enumerated()), id: \.offset) { _, entry in
                                Text(entry)
                                    .bookUI(12)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    GroupBox("本场提示") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(store.encounter(id: "guz-ambush")?.tactics ?? [], id: \.self) { tactic in
                                    Text("· \(tactic)")
                                        .bookUI(12)
                                        .foregroundStyle(.secondary)
                                }
                                Text("App 不自动判命中、豁免或规则；DM 用实体骰或骰子。")
                                    .bookUI(11)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                }
            }
            .padding(24)
            .frame(maxWidth: 820, alignment: .leading)
            .readingPage()
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .sheet(isPresented: $showMultiDamage) {
            MultiDamageSheet(run: run)
                .environment(store)
        }
        .sheet(item: $selectedRule) { rule in
            RuleSheetView(
                rule: rule,
                annotations: store.annotations(kind: .rule, targetID: rule.id, in: run),
                onAnnotationChange: { updated in
                    store.replaceAnnotations(kind: .rule, targetID: rule.id, with: updated, in: run)
                }
            )
            .environment(store)
        }
        .sheet(item: $selectedSpell) { spell in
            SpellSheetView(
                spell: spell,
                annotations: store.annotations(kind: .spell, targetID: spell.id, in: run),
                onAnnotationChange: { updated in
                    store.replaceAnnotations(kind: .spell, targetID: spell.id, with: updated, in: run)
                }
            )
            .environment(store)
        }
    }

    private var extraConditions: [String] {
        ["目盲", "魅惑", "耳聋", "力竭", "隐形", "麻痹", "石化", "震慑", "昏迷", "束缚", "失能"]
    }

    private func tempHPBinding(_ combatant: BattleCombatant) -> Binding<Int> {
        Binding(
            get: { run.battle?.combatants.first { $0.id == combatant.id }?.tempHP ?? 0 },
            set: { store.setTemporaryHP($0, forID: combatant.id, in: run) }
        )
    }

    private func hpBinding(_ combatant: BattleCombatant) -> Binding<Int> {
        Binding(
            get: { run.battle?.combatants.first { $0.id == combatant.id }?.hp ?? combatant.hp },
            set: { store.setHP($0, forID: combatant.id, in: run) }
        )
    }

    private func noteBinding(_ combatant: BattleCombatant) -> Binding<String> {
        Binding(
            get: { run.battle?.combatants.first { $0.id == combatant.id }?.notes ?? "" },
            set: { store.setCombatantNote($0, forID: combatant.id, in: run) }
        )
    }

    private func concentrationBinding(_ combatant: BattleCombatant) -> Binding<String> {
        Binding(
            get: {
                run.battle?.combatants.first { $0.id == combatant.id }?.concentration ?? ""
            },
            set: { value in
                store.setConcentration(value, forID: combatant.id, in: run)
            }
        )
    }
}

private struct MultiDamageSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Bindable var run: RunRecord
    @State private var amount = 1

    var body: some View {
        NavigationStack {
            List {
                Section("伤害数值") {
                    Stepper("每次 \(amount) 点", value: $amount, in: 1...100)
                }
                Section("目标") {
                    ForEach(run.battle?.combatants ?? []) { combatant in
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(combatant.name)
                                Text("HP \(combatant.hp)/\(combatant.maxHP)")
                                    .bookUI(11)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("-\(amount)") {
                                store.adjustHP(forID: combatant.id, delta: -amount, in: run)
                            }
                            .buttonStyle(.bordered)
                            .tint(Theme.red)
                            Button("+\(amount)") {
                                store.adjustHP(forID: combatant.id, delta: amount, in: run)
                            }
                            .buttonStyle(.bordered)
                            .tint(Theme.green)
                        }
                    }
                }
            }
            .navigationTitle("多目标伤害")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 460, minHeight: 380)
        .dismissOnBackgroundClick { dismiss() }
    }
}
