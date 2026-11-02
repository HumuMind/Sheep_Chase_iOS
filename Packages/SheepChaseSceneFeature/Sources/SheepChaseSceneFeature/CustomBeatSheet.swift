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
        BookFormSheet(
            title: "自定义节拍",
            primaryTitle: "添加",
            primaryDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onCancel: { dismiss() },
            onPrimary: add
        ) {
            BookFormSection("标题") {
                BookTextField("节拍标题", text: $title)
            }
            BookFormSection("类型") {
                Picker("类型", selection: $type) {
                    ForEach(types, id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
                .pickerStyle(.menu)
            }
            BookFormSection("正文") {
                BookTextEditor("这个节拍发生什么……", text: $text, minHeight: 110)
            }
            BookFormSection("朗读 / 描述") {
                BookTextEditor("可选，给玩家的描述……", text: $readAloud, minHeight: 70)
            }
            Text("自定义节拍只存在于当前开团，不会修改内容包。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func add() {
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
}
