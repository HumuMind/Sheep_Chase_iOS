import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

public struct SessionLogView: View {
    public init(run: RunRecord) {
        self.run = run
    }
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Bindable var run: RunRecord

    @State private var restoreCandidate: RunCheckpoint?
    @State private var showRestoreConfirmation = false

    private var activeSession: RunSession? {
        store.activeSession(in: run)
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: {
                guard let session = activeSession else { return "" }
                return run.sessions.first { $0.id == session.id }?.note ?? ""
            },
            set: { value in
                guard let session = activeSession else { return }
                store.updateSessionNote(value, sessionID: session.id, in: run)
            }
        )
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("本次聚会") {
                    if let session = activeSession {
                        LabeledContent("开始") {
                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        TextEditor(text: noteBinding)
                            .frame(minHeight: 80)
                            .overlay(alignment: .topLeading) {
                                if noteBinding.wrappedValue.isEmpty {
                                    Text("本次聚会记录：队伍去了哪里、发生了什么、下次从哪里继续……")
                                        .bookUI(12)
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 5)
                                        .allowsHitTesting(false)
                                }
                            }
                        Button("结束本次聚会并保存快照") {
                            store.endSession(note: noteBinding.wrappedValue, in: run)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.red)
                    } else {
                        Text("还没有进行中的聚会。开始后，结束时会自动保存本地快照。")
                            .bookUI(12)
                            .foregroundStyle(.secondary)
                        Button("开始本次聚会") {
                            store.startSession(in: run)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.red)
                    }
                }

                Section("聚会记录") {
                    if run.sessions.isEmpty {
                        Text("暂无记录。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(run.sessions.indices, id: \.self) { index in
                            let session = run.sessions[index]
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text("第 \(index + 1) 次聚会")
                                        .bookUI(13, weight: .medium)
                                    Spacer()
                                    Text(session.endedAt == nil ? "进行中" : "已结束")
                                        .bookUI(11)
                                        .foregroundStyle(session.endedAt == nil ? Theme.red : .secondary)
                                }
                                Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened))\(session.endedAt.map { " → \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "")")
                                    .bookUI(11)
                                    .foregroundStyle(.secondary)
                                if !session.note.isEmpty {
                                    Text(session.note)
                                        .bookUI(12)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if let lastBattle = run.lastBattle, run.battle == nil {
                    Section("上次战斗") {
                        Text("第 \(lastBattle.round) 轮 · \(lastBattle.combatants.count) 名参战者")
                            .bookUI(13, weight: .medium)
                        ForEach(Array(lastBattle.log.prefix(5)), id: \.self) { entry in
                            Text("· \(entry)")
                                .bookUI(11)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("本地快照") {
                    if run.checkpoints.isEmpty {
                        Text("暂无快照。开始/结束聚会、进入/结束战斗会自动创建快照。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(run.checkpoints) { checkpoint in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checkpoint.label)
                                        .bookUI(13, weight: .medium)
                                    Text(checkpoint.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .bookUI(11)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("恢复") {
                                    restoreCandidate = checkpoint
                                    showRestoreConfirmation = true
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    Button("现在创建手动快照") {
                        store.createCheckpoint("手动快照", in: run)
                    }
                    .buttonStyle(.borderless)
                }

                Section {
                    Text("快照只保存在本机当前开团中；JSON 备份仍建议在开团前导出一份。")
                        .bookUI(10)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.readingPaper)
            .environment(\.colorScheme, .light)
            .navigationTitle("聚会与快照")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
        .alert("恢复这个快照？", isPresented: $showRestoreConfirmation) {
            Button("取消", role: .cancel) {
                restoreCandidate = nil
            }
            Button("恢复", role: .destructive) {
                if let checkpoint = restoreCandidate {
                    store.restoreCheckpoint(checkpoint, in: run)
                }
                restoreCandidate = nil
            }
        } message: {
            Text("会覆盖当前场景、队伍、flags、便签、战斗和安全设置；建议先导出 JSON 备份。")
        }
    }
}
