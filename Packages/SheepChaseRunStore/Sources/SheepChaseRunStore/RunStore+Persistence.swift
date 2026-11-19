import Foundation
import SheepChasePersistence

@MainActor
extension RunStore {
    // MARK: - Persistence

    /// 保存并刷新 `updatedAt`；失败时回滚时间戳并把错误暴露给界面。
    @discardableResult
    public func commit(_ run: RunRecord) -> Bool {
        let previousUpdatedAt = run.updatedAt
        run.updatedAt = .now
        do {
            try repository.save()
            return true
        } catch {
            run.updatedAt = previousUpdatedAt
            reportPersistenceIssue("保存开团失败：\(error.localizedDescription)")
            return false
        }
    }

    @discardableResult
    public func persist() -> Bool {
        do {
            try repository.save()
            return true
        } catch {
            reportPersistenceIssue("保存开团失败：\(error.localizedDescription)")
            return false
        }
    }

    public func clearPersistenceError() {
        persistenceError = nil
    }

    func reportPersistenceIssue(_ message: String) {
        if let current = persistenceError, !current.isEmpty {
            persistenceError = current + "\n" + message
        } else {
            persistenceError = message
        }
    }
}
