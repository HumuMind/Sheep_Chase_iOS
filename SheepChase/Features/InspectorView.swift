import SwiftUI

struct InspectorView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @Binding var showAddPlayer: Bool

    private var tabSelection: Binding<InspectorTab> {
        Binding(
            get: { store.selectedTab },
            set: { tab in
                if tab == .battle {
                    store.setMode(.battle, in: run)
                } else {
                    store.selectedTab = tab
                }
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("检查器", selection: tabSelection) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)

            Divider()

            ScrollView {
                Group {
                    switch store.selectedTab {
                    case .party:
                        PartyInspector(run: run, showAddPlayer: $showAddPlayer)
                    case .battle:
                        BattleInspector(run: run)
                    case .notes:
                        NotesInspector(run: run)
                    case .rules:
                        RulesInspector()
                    }
                }
                .padding(14)
            }
        }
        .background(Theme.readingPaper)
        .environment(\.colorScheme, .light)
    }
}

struct PartyInspector: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @Binding var showAddPlayer: Bool
    @State private var editingMember: PartyMember?
    @State private var removingMember: PartyMember?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("队伍")
                    .font(.headline)
                Spacer()
                Text("\(run.party.count) 人")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                showAddPlayer = true
            } label: {
                Label("添加玩家", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            if run.party.isEmpty {
                ContentUnavailableView {
                    Label("还没有玩家", systemImage: "person.badge.plus")
                } description: {
                    Text("新建开团是空白的。添加姓名、等级、AC、HP、先攻和被动感知即可。")
                }
                .controlSize(.small)
            } else {
                VStack(spacing: 0) {
                    ForEach(run.party) { member in
                        PartyRowView(
                            member: member,
                            onEdit: { editingMember = member },
                            onRemove: { removingMember = member }
                        )
                        if member.id != run.party.last?.id {
                            Divider()
                        }
                    }
                }
            }

            Text("只记录战斗需要的最小数值；不管理角色卡、升级或法术位。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .sheet(item: $editingMember) { member in
            AddPlayerSheet(run: run, member: member)
                .environment(store)
        }
        .alert("移除玩家？", isPresented: Binding(
            get: { removingMember != nil },
            set: { if !$0 { removingMember = nil } }
        )) {
            Button("取消", role: .cancel) { removingMember = nil }
            Button("移除", role: .destructive) {
                if let member = removingMember {
                    store.removePlayer(member, from: run)
                }
                removingMember = nil
            }
        } message: {
            Text("会从当前开团移除 \(removingMember?.name ?? "该玩家")；战斗进行中不能移除。")
        }
    }
}

struct PartyRowView: View {
    let member: PartyMember
    var onEdit: () -> Void = {}
    var onRemove: () -> Void = {}

    private var hpColor: Color {
        let ratio = member.maxHP > 0 ? Double(member.hp) / Double(member.maxHP) : 0
        if ratio <= 0.25 { return Theme.redSoft }
        if ratio <= 0.5 { return Theme.amber }
        return Theme.green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(member.name)
                    .font(.body.weight(.medium))
                Text("Lv \(member.level) · \(member.role)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(member.hp)/\(member.maxHP)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Menu {
                    Button("编辑资料…") { onEdit() }
                    Button("移除玩家", role: .destructive) { onRemove() }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 18)
                .accessibilityLabel("玩家操作")
            }

            ProgressView(value: Double(member.hp), total: Double(max(member.maxHP, 1)))
                .tint(hpColor)
                .controlSize(.small)

            HStack(spacing: 8) {
                Text("AC \(member.ac)")
                Text("被动 \(member.passivePerception)")
                Text("先攻 \(member.initMod >= 0 ? "+" : "")\(member.initMod)")
                if let tempHP = member.tempHP, tempHP > 0 {
                    Text("临时 HP \(tempHP)")
                        .foregroundStyle(.blue)
                }
                if !member.conditions.isEmpty {
                    Text(member.conditions.joined(separator: "、"))
                        .foregroundStyle(.orange)
                }
                Spacer()
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct AddPlayerSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord
    let member: PartyMember?

    @State private var name: String
    @State private var role: String
    @State private var level: Int
    @State private var ac: Int
    @State private var maxHP: Int
    @State private var currentHP: Int
    @State private var tempHP: Int
    @State private var initMod: Int
    @State private var passivePerception: Int

    init(run: RunRecord, member: PartyMember? = nil) {
        self.run = run
        self.member = member
        _name = State(initialValue: member?.name ?? "")
        _role = State(initialValue: member?.role ?? "")
        _level = State(initialValue: member?.level ?? 4)
        _ac = State(initialValue: member?.ac ?? 14)
        _maxHP = State(initialValue: member?.maxHP ?? 20)
        _currentHP = State(initialValue: member?.hp ?? member?.maxHP ?? 20)
        _tempHP = State(initialValue: member?.tempHP ?? 0)
        _initMod = State(initialValue: member?.initMod ?? 0)
        _passivePerception = State(initialValue: member?.passivePerception ?? 12)
    }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && maxHP > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("玩家") {
                    TextField("姓名", text: $name)
                    TextField("职业 / 定位（可选）", text: $role)
                }

                Section("战斗数值") {
                    LabeledContent("等级") {
                        TextField("等级", value: $level, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    LabeledContent("AC") {
                        TextField("AC", value: $ac, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    LabeledContent("最大 HP") {
                        TextField("HP", value: $maxHP, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    LabeledContent("当前 HP") {
                        TextField("当前 HP", value: $currentHP, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    LabeledContent("临时 HP") {
                        TextField("临时 HP", value: $tempHP, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    LabeledContent("先攻加值") {
                        TextField("先攻加值", value: $initMod, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                    LabeledContent("被动感知") {
                        TextField("被动感知", value: $passivePerception, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                    }
                }

                Section {
                    Text("只记录战斗需要的最小数值，不创建完整角色卡。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(member == nil ? "添加玩家" : "编辑玩家")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(member == nil ? "添加" : "保存") {
                        if var existing = member {
                            existing.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            existing.role = role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "冒险者" : role
                            existing.level = level
                            existing.ac = ac
                            existing.maxHP = maxHP
                            existing.hp = min(max(currentHP, 0), maxHP)
                            existing.tempHP = max(tempHP, 0)
                            existing.initMod = initMod
                            existing.passivePerception = passivePerception
                            store.updatePlayer(existing, in: run)
                        } else {
                            store.addPlayer(
                                to: run,
                                name: name,
                                role: role,
                                level: level,
                                ac: ac,
                                maxHP: maxHP,
                                initMod: initMod,
                                passivePerception: passivePerception,
                                currentHP: currentHP,
                                tempHP: tempHP
                            )
                        }
                        dismiss()
                    }
                    .disabled(!canAdd)
                }
            }
        }
        .frame(minWidth: 430, minHeight: 430)
    }
}

struct RulesInspector: View {
    @Environment(RunStore.self) private var store
    @State private var query = ""

    private var rules: [ContentPack.RuleCard] {
        guard !query.isEmpty else { return store.content.rules }
        return store.content.rules.filter { rule in
            rule.term.localizedCaseInsensitiveContains(query)
                || rule.summary.localizedCaseInsensitiveContains(query)
                || rule.category.localizedCaseInsensitiveContains(query)
                || rule.aliases.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    private var spells: [ContentPack.SpellCard] {
        guard !query.isEmpty else { return store.content.spells }
        return store.content.spells.filter { spell in
            spell.name.localizedCaseInsensitiveContains(query)
                || spell.summary.localizedCaseInsensitiveContains(query)
                || spell.aliases.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("速查")
                .font(.headline)
            Text("本冒险精选；不是完整 SRD。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索规则、法术或别名", text: $query)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5).stroke(Theme.line, lineWidth: 1)
            )

            if query.isEmpty {
                Text("共 \(rules.count) 条规则 · \(spells.count) 个法术")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("找到 \(rules.count) 条规则 · \(spells.count) 个法术")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !rules.isEmpty {
                Text("规则")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.red)
                ForEach(rules) { rule in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.term)
                            .font(.body.weight(.medium))
                        Text(rule.category + " · " + rule.pageRef)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(rule.summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    Divider()
                }
            }

            if !spells.isEmpty {
                Text("法术")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.red)
                ForEach(spells) { spell in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(spell.name)
                            .font(.body.weight(.medium))
                        Text("\(spell.level) 环 · \(spell.castingTime) · \(spell.duration)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(spell.summary)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    Divider()
                }
            }

            if rules.isEmpty && spells.isEmpty {
                Text("没有匹配项。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            }
        }
    }
}
