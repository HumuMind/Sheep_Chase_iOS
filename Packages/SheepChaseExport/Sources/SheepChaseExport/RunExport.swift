import Foundation
import SheepChaseCore
import SheepChasePersistence

public struct RunSnapshot: Codable {
    public var formatVersion: Int
    public var exportedAt: Date
    public var contentVersion: String
    public var appVersion: String?
    public var run: RunStateSnapshot

    public init(
        formatVersion: Int = 1,
        exportedAt: Date = .now,
        contentVersion: String,
        appVersion: String? = nil,
        run: RunStateSnapshot
    ) {
        self.formatVersion = formatVersion
        self.exportedAt = exportedAt
        self.contentVersion = contentVersion
        self.appVersion = appVersion
        self.run = run
    }
}

public enum RunExport {
    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public static func snapshot(
        for run: RunRecord,
        contentVersion: String,
        appVersion: String
    ) -> RunSnapshot {
        RunSnapshot(
            exportedAt: .now,
            contentVersion: run.contentVersion.isEmpty ? contentVersion : run.contentVersion,
            appVersion: appVersion,
            run: run.stateSnapshot
        )
    }

    public static func data(
        for run: RunRecord,
        contentVersion: String,
        appVersion: String
    ) throws -> Data {
        try encoder().encode(snapshot(for: run, contentVersion: contentVersion, appVersion: appVersion))
    }

    public static func markdown(
        for run: RunRecord,
        content: ContentPack,
        appVersion: String
    ) -> String {
        let scene = content.scenes.first { $0.id == run.sceneID }
        var lines: [String] = []
        lines.append("# \(run.name)")
        lines.append("")
        lines.append("- 冒险：\(content.adventure.title)")
        lines.append("- App 版本：\(appVersion)")
        lines.append("- 内容版本：\(run.contentVersion.isEmpty ? content.manifest.version : run.contentVersion)")
        lines.append("- 当前场景：\(scene?.title ?? run.sceneID)")
        lines.append("- 导出时间：\(ISO8601DateFormatter().string(from: .now))")
        lines.append("")
        lines.append("## 队伍")
        if run.party.isEmpty {
            lines.append("（空）")
        } else {
            for member in run.party {
                lines.append("- \(member.name)｜Lv \(member.level) \(member.role)｜AC \(member.ac)｜HP \(member.hp)/\(member.maxHP)｜先攻 \(member.initMod >= 0 ? "+" : "")\(member.initMod)｜被动 \(member.passivePerception)")
            }
        }
        lines.append("")
        lines.append("## 本团状态")
        let activeFlags = content.flags.filter { run.flags[$0.id] ?? $0.defaultValue }
        if activeFlags.isEmpty {
            lines.append("（无）")
        } else {
            for flag in activeFlags {
                lines.append("- \(flag.label)")
            }
        }
        lines.append("")
        lines.append("## 便签")
        if run.stickyNotes.isEmpty {
            lines.append("（无）")
        } else {
            for note in run.stickyNotes {
                lines.append("### \(note.color.title)便签")
                lines.append(note.text.isEmpty ? "（空白）" : note.text)
                lines.append("")
            }
        }
        if !run.sceneNotes.isEmpty {
            lines.append("## 场景备注")
            for (sceneID, note) in run.sceneNotes.sorted(by: { $0.key < $1.key }) {
                let title = content.scenes.first { $0.id == sceneID }?.title ?? sceneID
                lines.append("### \(title)")
                lines.append(note.isEmpty ? "（空白）" : note)
                lines.append("")
            }
        }
        lines.append("## 聚会记录")
        if run.sessions.isEmpty {
            lines.append("（无）")
        } else {
            for (index, session) in run.sessions.enumerated() {
                let ended = session.endedAt.map { ISO8601DateFormatter().string(from: $0) } ?? "进行中"
                lines.append("- 第 \(index + 1) 次聚会：\(ISO8601DateFormatter().string(from: session.startedAt)) → \(ended)")
                if !session.note.isEmpty {
                    lines.append("  - \(session.note)")
                }
            }
        }
        lines.append("")
        lines.append("## 战斗日志")
        if let battle = run.battle ?? run.lastBattle {
            lines.append("- 状态：\(run.battle == nil ? "已结束（上次战斗）" : "进行中")｜阶段：\(battle.phase.rawValue)｜第 \(battle.round) 轮")
            lines.append("")
            for combatant in battle.combatants {
                lines.append("- \(combatant.name)｜先攻 \(combatant.initiative)｜AC \(combatant.ac)｜HP \(combatant.hp)/\(combatant.maxHP)\(combatant.conditions.isEmpty ? "" : "｜\(combatant.conditions.joined(separator: "、"))")")
            }
            lines.append("")
            for entry in battle.log {
                lines.append("- \(entry)")
            }
        } else {
            lines.append("（未开始战斗）")
        }
        lines.append("## 骰子记录")
        if run.diceHistory.isEmpty {
            lines.append("（无）")
        } else {
            for roll in run.diceHistory.prefix(20) {
                lines.append("- \(roll.command) = \(roll.total)")
            }
        }
        lines.append("")

        return lines.joined(separator: "\n") + "\n"
    }

    public static func safeFilename(_ name: String, suffix: String, extension ext: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        return "\(cleaned.isEmpty ? "荒野逐羊" : cleaned)_\(suffix).\(ext)"
    }
}

public enum RunBackupService {
    public static let versionKey = "lastBackupVersion"

    @discardableResult
    public static func createIfNeeded(
        runs: [RunRecord],
        contentVersion: String,
        appVersion: String,
        baseDirectory: URL,
        defaults: UserDefaults = .standard,
        keep: Int = 3
    ) -> URL? {
        let backupKey = "\(appVersion)/\(contentVersion)"
        guard defaults.string(forKey: versionKey) != backupKey else { return nil }

        let fileManager = FileManager.default
        let stamp = ISO8601DateFormatter()
            .string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let folder = baseDirectory
            .appendingPathComponent("SheepChase", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent("v\(appVersion)-\(stamp)", isDirectory: true)

        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            for run in runs {
                let data = try RunExport.data(
                    for: run,
                    contentVersion: contentVersion,
                    appVersion: appVersion
                )
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
            内容版本：\(contentVersion)
            导出时间：\(ISO8601DateFormatter().string(from: .now))

            每个 JSON 文件对应一个开团；可从 App 的开团库使用“导入开团备份…”恢复为新开团。
            这些文件只在本机，不会上传。
            """
            try readme.write(to: folder.appendingPathComponent("说明.txt"), atomically: true, encoding: .utf8)
            defaults.set(backupKey, forKey: versionKey)
            pruneBackups(in: baseDirectory.appendingPathComponent("SheepChase/Backups", isDirectory: true), keep: keep)
            return folder
        } catch {
            return nil
        }
    }

    private static func pruneBackups(in directory: URL, keep: Int) {
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
        for old in sorted.dropFirst(keep) {
            try? fileManager.removeItem(at: old)
        }
    }
}
