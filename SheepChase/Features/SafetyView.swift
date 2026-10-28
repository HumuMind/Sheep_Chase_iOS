import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct SafetySheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord

    @State private var lines = ""
    @State private var veils = ""
    @State private var pauseSignal = ""
    @State private var notes = ""
    @State private var restNote = ""

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

                Section("休息 / 暂停记录") {
                    HStack {
                        TextField("例如：中场休息、玩家要求暂停", text: $restNote)
                        Button("记录") {
                            store.recordRest(note: restNote, in: run)
                            restNote = ""
                        }
                        .buttonStyle(.bordered)
                    }
                    let log = run.safety.restLog ?? []
                    if log.isEmpty {
                        Text("还没有记录。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(log, id: \.self) { entry in
                            Text("· \(entry)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
            .environment(\.colorScheme, .light)
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
