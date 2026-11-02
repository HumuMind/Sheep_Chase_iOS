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
        BookFormSheet(
            title: "自定义人物",
            primaryTitle: "添加",
            primaryDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onCancel: { dismiss() },
            onPrimary: add
        ) {
            BookFormSection("身份") {
                BookTextField("姓名", text: $name)
                BookTextField("身份 / 角色", text: $role)
            }
            BookFormSection("角色描述") {
                BookTextEditor("这个人物是谁、想要什么、会怎么说话……", text: $description, minHeight: 150)
            }
            BookFormSection("关键特征") {
                BookTextEditor("每行一项", text: $traits, minHeight: 80)
            }
            Text("自定义 NPC 只存在于当前开团。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func add() {
        store.addCustomNPC(
            name: name,
            role: role,
            description: description,
            keyCharacteristics: traits.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty },
            in: run
        )
        dismiss()
    }
}
