import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import Foundation
import Observation
import SwiftData

@MainActor
extension RunStore {
    // MARK: - Version backup

    public func createVersionBackupIfNeeded() {
        let support = backupDirectory
        let appVersion = appVersion
        _ = RunBackupService.createIfNeeded(
            runs: runs,
            contentVersion: content.manifest.version,
            appVersion: appVersion,
            baseDirectory: support
        )
    }
}
