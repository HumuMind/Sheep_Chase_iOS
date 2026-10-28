import SwiftUI

struct NewRunSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("新建开团")
                .font(.title2.weight(.semibold))
            Text("新建记录完全空白；队伍、flags、战斗状态和便签都不会从旧团复制。")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("例如：周五团 · B 组", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("创建空白开团") {
                    store.createRun(name: name)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
