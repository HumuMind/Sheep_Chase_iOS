import SwiftUI
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI

struct CustomBeatSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let scene: ContentPack.AdventureScene
    let run: RunRecord

    @State private var title = ""
    @State private var type = "note"
    @State private var text = ""
    @State private var readAloud = ""

    private let types = [
        ("event", "事件"), ("decision", "决策"), ("roleplay", "扮演"),
        ("encounter", "遭遇"), ("transition", "转场"), ("note", "备注"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("标题") {
                    TextField("例如：队伍发现密道", text: $title)
                }
                Section("类型") {
                    Picker("类型", selection: $type) {
                        ForEach(types, id: \.0) { value, label in
                            Text(label).tag(value)
                        }
                    }
                }
                Section("内容") {
                    TextEditor(text: $text)
                        .frame(minHeight: 90)
                    TextEditor(text: $readAloud)
                        .frame(minHeight: 60)
                }
                Section {
                    Text("自定义节拍只存在于当前开团，不会修改内容包。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("自定义节拍")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        store.addCustomBeat(
                            sceneID: scene.id,
                            title: title,
                            type: type,
                            text: text,
                            readAloud: readAloud,
                            in: run
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 480)
    }
}
