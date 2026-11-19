import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct CustomMapPinSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let map: ContentPack.MapData
    let run: RunRecord

    @State private var label = ""
    @State private var note = ""
    @State private var x = 0.5
    @State private var y = 0.5

    var body: some View {
        BookFormSheet(
            title: "自定义图钉",
            primaryTitle: "添加",
            primaryDisabled: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onCancel: { dismiss() },
            onPrimary: add
        ) {
            BookFormSection("标签") {
                BookTextField("例如：密道入口", text: $label)
            }
            BookFormSection("备注") {
                BookTextEditor("这个位置有什么、为什么标记……", text: $note, minHeight: 80)
            }
            BookFormSection("位置") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("横向")
                            .bookSerif(13)
                        Slider(value: $x, in: 0...1)
                            .tint(Theme.red)
                        Text("\(Int(x * 100))%")
                            .bookSerif(11, monospaced: true)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("纵向")
                            .bookSerif(13)
                        Slider(value: $y, in: 0...1)
                            .tint(Theme.red)
                        Text("\(Int(y * 100))%")
                            .bookSerif(11, monospaced: true)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Text("自定义图钉只存在于当前开团，导出地图原图不会烧录图钉。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func add() {
        store.addCustomMapPin(
            mapID: map.id,
            x: x,
            y: y,
            label: label,
            note: note,
            in: run
        )
        dismiss()
    }
}
