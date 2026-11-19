import Foundation

/// 本地数据目录布局，以及旧版本散落文件的迁移。
///
/// 数据统一放在 `Application Support/SheepChase/`：
/// - `Data/SheepChase.store`：SwiftData 开团库
/// - `MyAdventureTemplates.json`：我的模组
/// - `../SheepChase/Backups/`：版本自动备份（由 RunBackupService 维护）
enum LocalDataLayout {
    static let folderName = "SheepChase"
    static let storeFileName = "SheepChase.store"
    static let templateFileName = "MyAdventureTemplates.json"

    static func appDirectory(in baseDirectory: URL) throws -> URL {
        let directory = baseDirectory.appendingPathComponent(folderName, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func templateURL(in baseDirectory: URL) throws -> URL {
        try migrateLegacyDataIfNeeded(in: baseDirectory)
        return try appDirectory(in: baseDirectory).appendingPathComponent(templateFileName)
    }

    static func storeURL(in baseDirectory: URL) throws -> URL {
        let dataDirectory = try appDirectory(in: baseDirectory)
            .appendingPathComponent("Data", isDirectory: true)
        try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        try migrateLegacyDataIfNeeded(in: baseDirectory)
        return dataDirectory.appendingPathComponent(storeFileName)
    }

    /// 把旧版放在 Application Support 根目录的数据搬进 `SheepChase/`。
    /// 目标已存在时不动旧文件，避免覆盖较新的数据。
    static func migrateLegacyDataIfNeeded(in baseDirectory: URL) throws {
        let fileManager = FileManager.default
        let appDirectory = try appDirectory(in: baseDirectory)
        let dataDirectory = appDirectory.appendingPathComponent("Data", isDirectory: true)
        try fileManager.createDirectory(at: dataDirectory, withIntermediateDirectories: true)

        let legacyStore = baseDirectory.appendingPathComponent("default.store")
        let newStore = dataDirectory.appendingPathComponent(storeFileName)
        if fileManager.fileExists(atPath: legacyStore.path),
           !fileManager.fileExists(atPath: newStore.path) {
            for suffix in ["", "-wal", "-shm"] {
                let source = URL(fileURLWithPath: legacyStore.path + suffix)
                guard fileManager.fileExists(atPath: source.path) else { continue }
                try fileManager.moveItem(at: source, to: URL(fileURLWithPath: newStore.path + suffix))
            }
        }

        let legacyTemplates = baseDirectory.appendingPathComponent(templateFileName)
        let newTemplates = appDirectory.appendingPathComponent(templateFileName)
        if fileManager.fileExists(atPath: legacyTemplates.path),
           !fileManager.fileExists(atPath: newTemplates.path) {
            try fileManager.moveItem(at: legacyTemplates, to: newTemplates)
        }
    }
}
