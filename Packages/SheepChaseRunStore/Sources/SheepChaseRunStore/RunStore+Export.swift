import Foundation
import Observation
import SheepChaseCore
import SheepChaseExport
import SheepChasePersistence
import SwiftData

@MainActor
extension RunStore {
    // MARK: - Version backup

    public func createVersionBackupIfNeeded() {
        do {
            _ = try RunBackupService.createIfNeeded(
                runs: runs,
                contentVersion: content.manifest.version,
                appVersion: appVersion,
                baseDirectory: backupDirectory
            )
        } catch {
            reportPersistenceIssue("自动备份失败：\(error.localizedDescription)")
        }
    }
}
