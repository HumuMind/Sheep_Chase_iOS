import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

public struct SafetySheet: View {
    public init(run: RunRecord) {
        self.run = run
        let safety = run.safety
        _lines = State(initialValue: safety.lines)
        _veils = State(initialValue: safety.veils)
        _pauseSignal = State(initialValue: safety.pauseSignal)
        _notes = State(initialValue: safety.notes)
    }
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord

    @State private var lines = ""
    @State private var veils = ""
    @State private var pauseSignal = ""
    @State private var notes = ""
    @State private var restNote = ""

    public var body: some View {
        BookFormSheet(
            title: "桌面安全",
            primaryTitle: "保存",
            onCancel: { dismiss() },
            onPrimary: save
        ) {
            BookFormSection("本冒险的内容提示") {
                ForEach(store.adventure.contentWarnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .bookSerif(13)
                }
            }

            BookFormSection("Lines（完全跳过）") {
                BookTextEditor("例如：不描写动物受伤的细节。", text: $lines, minHeight: 58)
            }

            BookFormSection("Veils（淡出处理）") {
                BookTextEditor("例如：变形失败时只描述结果，不描写过程。", text: $veils, minHeight: 58)
            }

            BookFormSection("暂停暗号") {
                BookTextField("例如：有人说“休息一下”就暂停", text: $pauseSignal)
            }

            BookFormSection("本团备注") {
                BookTextEditor("写点什么……", text: $notes, minHeight: 58)
            }

            BookFormSection("休息 / 暂停记录") {
                HStack {
                    BookTextField("例如：中场休息、玩家要求暂停", text: $restNote)
                    Button("记录") {
                        store.recordRest(note: restNote, in: run)
                        restNote = ""
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.red)
                }
                let log = run.safety.restLog ?? []
                if log.isEmpty {
                    Text("还没有记录。")
                        .bookSerif(11)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(log, id: \.self) { entry in
                        Text("· \(entry)")
                            .bookSerif(12)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text("这些设置只保存在当前开团，不上传。需要临时隐藏内容时，用工具栏的“遮屏”。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        store.updateSafety(
            SafetyState(lines: lines, veils: veils, pauseSignal: pauseSignal, notes: notes),
            in: run
        )
        dismiss()
    }
}
