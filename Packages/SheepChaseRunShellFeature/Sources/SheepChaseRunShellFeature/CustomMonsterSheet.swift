import SwiftUI
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI

struct CustomMonsterSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord

    @State private var name = ""
    @State private var size = "中型"
    @State private var type = "怪兽"
    @State private var alignment = "无阵营"
    @State private var ac = 13
    @State private var hp = 20
    @State private var initiativeModifier = 0
    @State private var actionText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("身份") {
                    TextField("名称", text: $name)
                    TextField("体型", text: $size)
                    TextField("类型", text: $type)
                    TextField("阵营", text: $alignment)
                }
                Section("数值") {
                    Stepper("AC \(ac)", value: $ac, in: 1...40)
                    Stepper("HP \(hp)", value: $hp, in: 1...999)
                    Stepper("先攻调整 \(initiativeModifier >= 0 ? "+" : "")\(initiativeModifier)", value: $initiativeModifier, in: -5...10)
                }
                Section("动作") {
                    TextEditor(text: $actionText)
                        .frame(minHeight: 90)
                }
                Section {
                    Text("自定义怪物只存在于当前开团，可在战斗筹备中选择。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("自定义怪物")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        store.addCustomMonster(
                            name: name,
                            size: size,
                            type: type,
                            alignment: alignment,
                            ac: ac,
                            hp: hp,
                            initiativeModifier: initiativeModifier,
                            actionText: actionText,
                            in: run
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}
