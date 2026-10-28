import SwiftUI

struct SessionLogView: View {
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

    var body: some View {
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
                                        .font(.callout)
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
                            .font(.callout)
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
                                        .font(.body.weight(.medium))
                                    Spacer()
                                    Text(session.endedAt == nil ? "进行中" : "已结束")
                                        .font(.caption)
                                        .foregroundStyle(session.endedAt == nil ? Theme.red : .secondary)
                                }
                                Text("\(session.startedAt.formatted(date: .abbreviated, time: .shortened))\(session.endedAt.map { " → \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !session.note.isEmpty {
                                    Text(session.note)
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
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
                                        .font(.body.weight(.medium))
                                    Text(checkpoint.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
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
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.readingPaper)
            .navigationTitle("聚会与快照")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 560)
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
