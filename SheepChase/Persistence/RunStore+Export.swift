import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import Foundation
import Observation
import SwiftData

@MainActor
extension RunStore {
    // MARK: - Version backup

    func createVersionBackupIfNeeded(appVersion: String) {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        _ = RunBackupService.createIfNeeded(
            runs: runs,
            contentVersion: content.manifest.version,
            appVersion: appVersion,
            baseDirectory: support
        )
    }
}
