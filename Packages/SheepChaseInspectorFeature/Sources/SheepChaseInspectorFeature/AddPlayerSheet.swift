import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

public struct AddPlayerSheet: View {
    public init(run: RunRecord, member: PartyMember? = nil) {
        self.run = run
        self.member = member
        _name = State(initialValue: member?.name ?? "")
        _role = State(initialValue: member?.role ?? "")
        _level = State(initialValue: member?.level ?? 4)
        _ac = State(initialValue: member?.ac ?? 14)
        _maxHP = State(initialValue: member?.maxHP ?? 20)
        _currentHP = State(initialValue: member?.hp ?? member?.maxHP ?? 20)
        _initMod = State(initialValue: member?.initMod ?? 0)
        _passivePerception = State(initialValue: member?.passivePerception ?? 12)
    }
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
    @State private var initMod: Int
    @State private var passivePerception: Int

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && maxHP > 0
    }

    public var body: some View {
        BookFormSheet(
            title: member == nil ? "添加玩家" : "编辑玩家",
            primaryTitle: member == nil ? "添加" : "保存",
            primaryDisabled: !canAdd,
            onCancel: { dismiss() },
            onPrimary: save
        ) {
            BookFormSection("玩家") {
                BookTextField("姓名", text: $name)
                BookTextField("职业 / 定位（可选）", text: $role)
            }
            BookFormSection("战斗数值") {
                BookNumberField("等级", value: $level)
                BookNumberField("AC", value: $ac)
                BookNumberField("最大 HP", value: $maxHP)
                BookNumberField("当前 HP", value: $currentHP)
                BookNumberField("先攻加值", value: $initMod)
                BookNumberField("被动感知", value: $passivePerception)
            }
            Text("只记录战斗需要的最小数值，不创建完整角色卡。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        if var existing = member {
            existing.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.role = role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "冒险者" : role
            existing.level = level
            existing.ac = ac
            existing.maxHP = maxHP
            existing.hp = min(max(currentHP, 0), maxHP)
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
                currentHP: currentHP
            )
        }
        dismiss()
    }
}
