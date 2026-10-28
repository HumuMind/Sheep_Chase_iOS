import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
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
        _tempHP = State(initialValue: member?.tempHP ?? 0)
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
    @State private var tempHP: Int
    @State private var initMod: Int
    @State private var passivePerception: Int

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && maxHP > 0
    }

    public var body: some View {
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
