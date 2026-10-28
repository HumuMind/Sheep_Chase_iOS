import SwiftUI

struct BattleActiveView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    private var battle: BattleState? { run.battle }
    private var active: BattleCombatant? { store.activeCombatant(in: run) }
    private var activeMonster: ContentPack.Monster? {
        guard let baseID = active?.baseID else { return nil }
        return store.monster(id: baseID)
    }

    @State private var lastRoll: String?
    @State private var showMultiDamage = false
    @State private var selectedRule: ContentPack.RuleCard?
    @State private var selectedSpell: ContentPack.SpellCard?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("战斗 · 第 \(battle?.round ?? 1) 轮")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(store.encounter(id: "guz-ambush")?.title ?? "战斗")
                            .font(.largeTitle.weight(.semibold))
                    }
                    Spacer()
                    if let battle, battle.phase == .active {
                        Button("撤销上一步") {
                            store.undoBattle(in: run)
                        }
                        .buttonStyle(.bordered)
                        .disabled(battle.undo == nil)
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
                    GroupBox("当前回合") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(active.name)
                                    .font(.title2.weight(.semibold))
                                Text(active.kind == .player ? "玩家" : "怪物")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("AC \(active.ac)")
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }

                            HStack(spacing: 16) {
                                Text("HP \(active.hp) / \(active.maxHP)")
                                    .font(.body.monospacedDigit())
                                Text("先攻 \(active.initiative)")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                HStack(spacing: 4) {
                                    Text("临时")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("0", value: tempHPBinding(active), format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 46)
                                }
                                Spacer()
                                TextField("专注：例如加速术", text: concentrationBinding(active))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 190)
                            }

                            if let concentration = active.concentration, !concentration.isEmpty {
                                Text("专注中：\(concentration)。受到伤害时按专注规则进行体质豁免。")
                                    .font(.caption)
                                    .foregroundStyle(Theme.red)
                            }

                            ProgressView(value: Double(active.hp), total: Double(max(active.maxHP, 1)))
                                .tint(active.hp <= active.maxHP / 4 ? Theme.redSoft : Theme.green)

                            HStack(spacing: 5) {
                                ForEach([-1, -5, -10, 5], id: \.self) { delta in
                                    Button(delta > 0 ? "+\(delta)" : "\(delta)") {
                                        store.adjustHP(delta, in: run)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(delta > 0 ? Theme.green : Theme.inkSoft)
                                }

                                Divider().frame(height: 18)

                                ForEach(["受擒", "倒地", "恐慌", "中毒"], id: \.self) { condition in
                                    let on = active.conditions.contains(condition)
                                    Button(condition) {
                                        store.toggleCondition(condition, in: run)
                                    }
                                    .buttonStyle(.plain)
                                    .font(.caption)
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
                                        .font(.caption)
                                }
                                .menuStyle(.borderlessButton)
                                .help("更多状态")
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }

                GroupBox("骰子") {
                    HStack(spacing: 6) {
                        ForEach([4, 6, 8, 10, 12, 20], id: \.self) { sides in
                            Button("d\(sides)") {
                                let value = store.rollDice(sides: sides, in: run)
                                lastRoll = "d\(sides) = \(value)"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        Divider().frame(height: 18)
                        Button("d20+5") {
                            let value = store.rollDice(sides: 20, modifier: 5, in: run)
                            lastRoll = "d20+5 = \(value)"
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        Spacer()
                        Text(lastRoll ?? "尚未掷骰")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(lastRoll == nil ? .secondary : Theme.ink)
                    }
                    .padding(.vertical, 3)
                }

                HStack(alignment: .top, spacing: 12) {
                    GroupBox("战斗日志") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array((battle?.log ?? []).prefix(9).enumerated()), id: \.offset) { _, entry in
                                Text(entry)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    if let monster = activeMonster {
                        GroupBox("数据块 · \(monster.name)") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(monster.size)\(monster.type) · \(monster.alignment)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let vulnerabilities = monster.damageVulnerabilities, !vulnerabilities.isEmpty {
                                    Text("易伤：\(vulnerabilities.joined(separator: "、"))")
                                        .font(.caption)
                                        .foregroundStyle(Theme.red)
                                }
                                ForEach((monster.traits ?? []) + monster.actions) { pair in
                                    Text("\(pair.name)。\(pair.text)")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                if let ruleIDs = monster.ruleIds, !ruleIDs.isEmpty {
                                    HStack(spacing: 5) {
                                        Text("规则")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        ForEach(ruleIDs, id: \.self) { ruleID in
                                            if let rule = store.rule(id: ruleID) {
                                                Button(rule.term) {
                                                    selectedRule = rule
                                                }
                                                .buttonStyle(.borderless)
                                                .font(.caption)
                                                .foregroundStyle(Theme.red)
                                            }
                                        }
                                    }
                                }
                                if let spellIDs = monster.spellIds, !spellIDs.isEmpty {
                                    Menu {
                                        ForEach(spellIDs, id: \.self) { spellID in
                                            if let spell = store.spell(id: spellID) {
                                                Button(spell.name) { selectedSpell = spell }
                                            }
                                        }
                                    } label: {
                                        Label("打开法术（\(spellIDs.count)）", systemImage: "book.closed")
                                            .font(.caption)
                                    }
                                    .menuStyle(.borderlessButton)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } else {
                        GroupBox("本场提示") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(store.encounter(id: "guz-ambush")?.tactics ?? [], id: \.self) { tactic in
                                    Text("· \(tactic)")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                Text("App 不自动判命中、豁免或规则；DM 用实体骰或骰子。")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
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
            RuleSheetView(rule: rule)
                .environment(store)
        }
        .sheet(item: $selectedSpell) { spell in
            SpellSheetView(spell: spell)
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
                                    .font(.caption)
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
    }
}
