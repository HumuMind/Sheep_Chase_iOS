import SwiftUI
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI

struct CustomNPCSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord

    @State private var name = ""
    @State private var role = ""
    @State private var description = ""
    @State private var traits = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("身份") {
                    TextField("姓名", text: $name)
                    TextField("身份 / 角色", text: $role)
                }
                Section("角色描述") {
                    TextEditor(text: $description)
                        .frame(minHeight: 140)
                }
                Section("关键特征") {
                    TextField("每行一项", text: $traits, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Text("自定义 NPC 只存在于当前开团。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("自定义人物")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        store.addCustomNPC(
                            name: name,
                            role: role,
                            description: description,
                            keyCharacteristics: traits.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
                            in: run
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 480)
    }
}
