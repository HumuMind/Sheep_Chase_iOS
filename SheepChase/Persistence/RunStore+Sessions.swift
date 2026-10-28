import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import Foundation
import Observation
import SwiftData

@MainActor
extension RunStore {
    // MARK: - Sessions, checkpoints, run management and safety

    func activeSession(in run: RunRecord) -> RunSession? {
        run.sessions.last { $0.endedAt == nil }
    }

    func startSession(in run: RunRecord) {
        guard activeSession(in: run) == nil else {
            notify("本次聚会已经开始")
            return
        }
        var sessions = run.sessions
        sessions.append(RunSession(startedAt: .now))
        run.sessions = sessions
        commit(run)
        createCheckpoint("开始聚会", in: run)
        notify("开始第 \(sessions.count) 次聚会")
    }

    func endSession(note: String, in run: RunRecord) {
        guard var session = activeSession(in: run) else { return }
        session.endedAt = .now
        session.note = note
        var sessions = run.sessions
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
        run.sessions = sessions
        commit(run)
        createCheckpoint("结束聚会", in: run)
        notify("聚会记录已保存")
    }

    func updateSessionNote(_ note: String, sessionID: UUID, in run: RunRecord) {
        var sessions = run.sessions
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].note = note
        run.sessions = sessions
        commit(run)
    }

    func createCheckpoint(_ label: String, in run: RunRecord) {
        var checkpoints = run.checkpoints
        checkpoints.insert(RunCheckpoint(label: label, state: run.stateSnapshot), at: 0)
        run.checkpoints = Array(checkpoints.prefix(12))
        commit(run)
    }

    func restoreCheckpoint(_ checkpoint: RunCheckpoint, in run: RunRecord) {
        run.apply(checkpoint.state)
        run.updatedAt = .now
        commit(run)
        notify("已恢复到「\(checkpoint.label)」")
    }

    func updateSafety(_ safety: SafetyState, in run: RunRecord) {
        run.safety = safety
        commit(run)
    }

    func recordRest(note: String, in run: RunRecord) {
        var safety = run.safety
        var log = safety.restLog ?? []
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        log.append("\(timestamp)　\(note.isEmpty ? "暂停 / 休息" : note)")
        safety.restLog = Array(log.suffix(20))
        run.safety = safety
        commit(run)
        notify("已记录休息")
    }

    func rename(_ run: RunRecord, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        run.name = trimmed
        commit(run)
        notify("开团已重命名")
    }

    func setArchived(_ archived: Bool, in run: RunRecord) {
        run.isArchived = archived
        if archived, selectedRunID == run.id {
            selectedRunID = nil
        }
        commit(run)
        notify(archived ? "已归档开团" : "已恢复开团")
    }

    func delete(_ run: RunRecord) {
        if selectedRunID == run.id { selectedRunID = nil }
        runs.removeAll { $0.id == run.id }
        repository.delete(run)
        persist()
        notify("开团已删除")
    }

    func deleteAllData() {
        selectedRunID = nil
        for run in runs {
            repository.delete(run)
        }
        runs.removeAll()
        persist()
        notify("全部开团数据已删除")
    }

    func exportJSON(for run: RunRecord) throws -> Data {
        try RunExport.data(for: run, contentVersion: content.manifest.version)
    }

    func exportMarkdown(for run: RunRecord) -> String {
        RunExport.markdown(for: run, content: content)
    }

    func importRun(from data: Data) throws -> RunRecord {
        let snapshot = try RunExport.decoder().decode(RunSnapshot.self, from: data)
        let payload = snapshot.run
        let sceneID = scene(id: payload.sceneID) != nil ? payload.sceneID : (scenes.first?.id ?? "scene-1")
        let run = RunRecord(
            name: payload.name.isEmpty ? "导入开团" : "\(payload.name)（导入）",
            sceneID: sceneID,
            beatID: payload.beatID,
            contentVersion: content.manifest.version
        )
        run.apply(payload)
        run.contentVersion = content.manifest.version
        if !run.name.hasSuffix("（导入）") {
            run.name = "\(run.name)（导入）"
        }
        run.updatedAt = .now
        repository.insert(run)
        runs.append(run)
        selectedRunID = run.id
        persist()
        notify("已导入为新开团")
        return run
    }
}
