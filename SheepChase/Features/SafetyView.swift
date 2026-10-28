import SwiftUI

struct SafetySheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord

    @State private var lines = ""
    @State private var veils = ""
    @State private var pauseSignal = ""
    @State private var notes = ""

    init(run: RunRecord) {
        self.run = run
        let safety = run.safety
        _lines = State(initialValue: safety.lines)
        _veils = State(initialValue: safety.veils)
        _pauseSignal = State(initialValue: safety.pauseSignal)
        _notes = State(initialValue: safety.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("本冒险的内容提示") {
                    ForEach(store.adventure.contentWarnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .font(.callout)
                    }
                }

                Section("Lines（完全跳过）") {
                    TextEditor(text: $lines)
                        .frame(minHeight: 54)
                    Text("例如：不描写动物受伤的细节。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Veils（淡出处理）") {
                    TextEditor(text: $veils)
                        .frame(minHeight: 54)
                    Text("例如：变形失败时只描述结果，不描写过程。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("暂停暗号") {
                    TextField("例如：有人说“休息一下”就暂停", text: $pauseSignal)
                }

                Section("本团备注") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 54)
                }

                Section {
                    Text("这些设置只保存在当前开团，不上传。需要临时隐藏内容时，用工具栏的“遮屏”。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.readingPaper)
            .navigationTitle("桌面安全")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.updateSafety(
                            SafetyState(lines: lines, veils: veils, pauseSignal: pauseSignal, notes: notes),
                            in: run
                        )
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(minWidth: 520, minHeight: 560)
    }
}
