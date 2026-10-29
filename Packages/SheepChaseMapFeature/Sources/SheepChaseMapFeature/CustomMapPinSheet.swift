import SwiftUI
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI

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
        NavigationStack {
            Form {
                Section("标签") {
                    TextField("例如：密道入口", text: $label)
                }
                Section("备注") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
                Section("位置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("横向 \(Int(x * 100))%")
                        Slider(value: $x, in: 0...1)
                        Text("纵向 \(Int(y * 100))%")
                        Slider(value: $y, in: 0...1)
                    }
                }
                Section {
                    Text("自定义图钉只存在于当前开团，导出地图原图不会烧录图钉。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("自定义图钉")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
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
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 460, minHeight: 420)
    }
}
