import Foundation
import Observation
import SwiftData

@MainActor
extension RunStore {
    // MARK: - Version backup

    func createVersionBackupIfNeeded(appVersion: String) {
        let defaults = UserDefaults.standard
        let key = "lastBackupVersion"
        let backupKey = "\(appVersion)/\(content.manifest.version)"
        guard defaults.string(forKey: key) != backupKey else { return }

        let fileManager = FileManager.default
        guard let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let stamp = ISO8601DateFormatter()
            .string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let folder = support
            .appendingPathComponent("SheepChase", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent("v\(appVersion)-\(stamp)", isDirectory: true)

        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            for run in runs {
                let data = try RunExport.data(for: run, contentVersion: content.manifest.version)
                let filename = RunExport.safeFilename(
                    run.name,
                    suffix: "自动备份-\(run.id.uuidString.prefix(8))",
                    extension: "json"
                )
                try data.write(to: folder.appendingPathComponent(filename), options: [.atomic])
            }
            let readme = """
            《荒野逐羊》自动备份
            App 版本：\(appVersion)
            内容版本：\(content.manifest.version)
            导出时间：\(ISO8601DateFormatter().string(from: .now))

            每个 JSON 文件对应一个开团；可从 App 的开团库使用“导入开团备份…”恢复为新开团。
            这些文件只在本机，不会上传。
            """
            try readme.write(to: folder.appendingPathComponent("说明.txt"), atomically: true, encoding: .utf8)
            defaults.set(backupKey, forKey: key)
            pruneBackups(in: support.appendingPathComponent("SheepChase/Backups", isDirectory: true))
        } catch {
            // 备份失败不应阻止 App 启动；用户仍可手动导出。
            print("自动备份失败：\(error)")
        }
    }

    private func pruneBackups(in directory: URL) {
        let fileManager = FileManager.default
        guard let folders = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        let sorted = folders.sorted {
            let lhs = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lhs > rhs
        }
        for old in sorted.dropFirst(3) {
            try? fileManager.removeItem(at: old)
        }
    }
}
