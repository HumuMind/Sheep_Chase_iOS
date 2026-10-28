import SwiftUI
import SheepChaseCore

public struct NPCSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let npc: ContentPack.NPC

    public init(npc: ContentPack.NPC) {
        self.npc = npc
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    GroupBox("玩家可见") {
                        Text(npc.publicDescription)
                            .font(.body)
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                    GroupBox("DM 秘密") {
                        Text(npc.dmDescription)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                    GroupBox("扮演提示") {
                        VStack(alignment: .leading, spacing: 8) {
                            labeled("语气", npc.voice)
                            labeled("动机", npc.motivation)
                            labeled("态度", attitudeLabel)
                            if let characteristics = npc.keyCharacteristics, !characteristics.isEmpty {
                                labeled("关键特征", characteristics.joined(separator: " · "))
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    if !npc.knows.isEmpty || !npc.wants.isEmpty || !npc.secrets.isEmpty {
                        GroupBox("情报") {
                            VStack(alignment: .leading, spacing: 10) {
                                list("知道", npc.knows)
                                list("想要", npc.wants)
                                list("秘密", npc.secrets, tint: Theme.red)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    if !npc.sampleLines.isEmpty {
                        GroupBox("示例台词") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(npc.sampleLines, id: \.self) { line in
                                    Text("“\(line)”")
                                        .font(Theme.serif(14))
                                        .foregroundStyle(Theme.inkSoft)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    if let relationships = npc.relationships, !relationships.isEmpty {
                        GroupBox("关系") {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(relationships) { relationship in
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(relationship.label)
                                            .font(.callout.weight(.medium))
                                        Text(relationship.note)
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    if let sourceRef = npc.sourceRef {
                        Text(sourceRef)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: 680, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(BookPaperBackground())
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(npc.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .frame(minWidth: 560, minHeight: 560)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(String(npc.name.prefix(1)))
                .font(Theme.serif(30, weight: .semibold))
                .frame(width: 54, height: 54)
                .background(Theme.paperDeep, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(npc.role)
                    .font(.title3.weight(.medium))
                Text("DM 专属 NPC 卡")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(attitudeLabel)
                .font(.caption)
                .foregroundStyle(npc.attitude == "hostile" ? Theme.red : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .overlay(
                    Capsule().stroke(Theme.line, lineWidth: 1)
                )
        }
    }

    private var attitudeLabel: String {
        switch npc.attitude {
        case "friendly": "友善"
        case "hostile": "敌对"
        case "neutral": "中立"
        default: "未知"
        }
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    private func list(_ label: String, _ values: [String], tint: Color = Theme.inkSoft) -> some View {
        Group {
            if !values.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    ForEach(values, id: \.self) { value in
                        Text("· \(value)")
                            .font(.callout)
                            .foregroundStyle(tint)
                    }
                }
            }
        }
    }
}
