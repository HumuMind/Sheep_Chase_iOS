import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct RunSnapshot: Codable {
    var formatVersion: Int = 1
    var exportedAt: Date
    var contentVersion: String
    var run: RunPayload

    struct RunPayload: Codable {
        var name: String
        var sceneID: String
        var beatID: String
        var mode: RunMode
        var party: [PartyMember]
        var flags: [String: Bool]
        var notes: [StickyNote]
        var battle: BattleState?
        var safety: SafetyState
    }
}

struct RunExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText] }
    static var writableContentTypes: [UTType] { [.json, .plainText] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum RunExport {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func snapshot(for run: RunRecord, contentVersion: String) -> RunSnapshot {
        RunSnapshot(
            exportedAt: .now,
            contentVersion: run.contentVersion.isEmpty ? contentVersion : run.contentVersion,
            run: RunSnapshot.RunPayload(
                name: run.name,
                sceneID: run.sceneID,
                beatID: run.beatID,
                mode: run.mode,
                party: run.party,
                flags: run.flags,
                notes: run.stickyNotes,
                battle: run.battle,
                safety: run.safety
            )
        )
    }

    static func data(for run: RunRecord, contentVersion: String) throws -> Data {
        try encoder().encode(snapshot(for: run, contentVersion: contentVersion))
    }

    static func markdown(for run: RunRecord, content: ContentPack) -> String {
        let scene = content.scenes.first { $0.id == run.sceneID }
        var lines: [String] = []
        lines.append("# \(run.name)")
        lines.append("")
        lines.append("- 冒险：\(content.adventure.title)")
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
        lines.append("## 战斗日志")
        if let battle = run.battle {
            lines.append("- 阶段：\(battle.phase.rawValue)｜第 \(battle.round) 轮")
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
        return lines.joined(separator: "\n") + "\n"
    }

    static func safeFilename(_ name: String, suffix: String, extension ext: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:\\?%*|\"<>")
        let cleaned = name.components(separatedBy: invalid).joined(separator: "_")
        return "\(cleaned.isEmpty ? "荒野逐羊" : cleaned)_\(suffix).\(ext)"
    }
}
