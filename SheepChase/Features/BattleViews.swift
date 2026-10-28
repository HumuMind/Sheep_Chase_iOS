import SwiftUI

struct BattleCenterView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    var body: some View {
        Group {
            if let battle = run.battle {
                switch battle.phase {
                case .select:
                    BattleSelectView(run: run)
                case .initiative:
                    BattleInitiativeView(run: run)
                case .active:
                    BattleActiveView(run: run)
                }
            } else {
                ContentUnavailableView {
                    Label("还没有战斗筹备", systemImage: "shield")
                } description: {
                    Text("从场景遭遇进入，或点击下方按钮开始。")
                } actions: {
                    Button("开始战斗筹备") {
                        store.openBattleSetup(for: run)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                }
            }
        }
    }
}

private struct BattleSelectView: View {
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

private struct BattleInitiativeView: View {
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

private struct BattleActiveView: View {
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

struct BattleInspector: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    private var battle: BattleState? { run.battle }

    var body: some View {
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

private struct BattleStepsView: View {
    let phase: BattlePhase

    var body: some View {
        HStack(spacing: 18) {
            step(number: 1, title: "选择参战者", active: phase == .select)
            step(number: 2, title: "填写先攻", active: phase == .initiative)
            step(number: 3, title: "按轮次战斗", active: phase == .active)
        }
        .padding(.vertical, 2)
    }

    private func step(number: Int, title: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: active ? "\(number).circle.fill" : "\(number).circle")
                .foregroundStyle(active ? Theme.red : .secondary)
            Text(title)
                .font(.callout.weight(active ? .medium : .regular))
                .foregroundStyle(active ? .primary : .secondary)
        }
    }
}

private struct PlayerSelectionRow: View {
    let member: PartyMember
    let selected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(String(member.name.prefix(1)))
                .font(.caption.weight(.semibold))
                .frame(width: 24, height: 24)
                .background(.quaternary, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(member.name)
                    .font(.body.weight(.medium))
                Text("Lv \(member.level) · \(member.role)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(selected ? "已加入" : "添加") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 5)
    }
}
