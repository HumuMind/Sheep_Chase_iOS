import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct CustomBeatSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let scene: ContentPack.AdventureScene
    let run: RunRecord
    let beat: RunCustomBeat?

    @State private var title: String
    @State private var type: String
    @State private var text: String
    @State private var readAloud: String

    private let types = [
        ("event", "事件"), ("decision", "决策"), ("roleplay", "扮演"),
        ("encounter", "遭遇"), ("transition", "转场"), ("note", "备注"),
    ]

    init(scene: ContentPack.AdventureScene, run: RunRecord, beat: RunCustomBeat? = nil) {
        self.scene = scene
        self.run = run
        self.beat = beat
        _title = State(initialValue: beat?.title ?? "")
        _type = State(initialValue: beat?.type ?? "note")
        _text = State(initialValue: beat?.text ?? "")
        _readAloud = State(initialValue: beat?.readAloud ?? "")
    }

    var body: some View {
        BookFormSheet(
            title: beat == nil ? "自定义节拍" : "编辑自定义节拍",
            primaryTitle: beat == nil ? "添加" : "保存",
            primaryDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onCancel: { dismiss() },
            onPrimary: save
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
            Text("自定义节拍只存在于当前开团，不会修改内容包；保存后可继续编辑或删除。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        if let beat {
            store.updateCustomBeat(
                beat.id,
                title: title,
                type: type,
                text: text,
                readAloud: readAloud,
                in: run
            )
        } else {
            store.addCustomBeat(
                sceneID: scene.id,
                title: title,
                type: type,
                text: text,
                readAloud: readAloud,
                in: run
            )
        }
        dismiss()
    }
}
