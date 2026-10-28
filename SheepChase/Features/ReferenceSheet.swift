import SwiftUI

enum ContentImage {
    static func name(for assetID: String) -> String? {
        switch assetID {
        case "cover": "Cover"
        case "map-treehouse": "Map"
        case "sheep-illustration": "Sheep"
        default: nil
        }
    }
}

struct HandoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let handout: ContentPack.Handout
    let asset: ContentPack.Asset?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("玩家可见") {
                        Text(handout.playerText)
                            .font(.body)
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }

                    if let imageAssetID = handout.imageAssetId,
                       let imageName = ContentImage.name(for: imageAssetID) {
                        GroupBox("图片") {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Theme.line, lineWidth: 1)
                                )
                                .padding(.vertical, 3)
                        }
                    }

                    if let dmText = handout.dmText {
                        GroupBox("DM 备注") {
                            Text(dmText)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineSpacing(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 3)
                        }
                    }

                    if let credit = asset?.credit {
                        Text("图片：\(credit)")
                            .font(.caption2)
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
            .navigationTitle(handout.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
    }
}

struct ItemSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ContentPack.Item

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox(item.kind) {
                        Text(item.summary)
                            .font(.body)
                            .lineSpacing(3)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }
                    if let pageRef = item.pageRef {
                        Text(pageRef)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: 620, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(BookPaperBackground())
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(item.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 360)
    }
}

struct RuleSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let rule: ContentPack.RuleCard

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox(rule.term) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(rule.category + " · " + rule.pageRef)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(rule.summary)
                                .font(.body)
                                .lineSpacing(3)
                                .textSelection(.enabled)
                            if !rule.aliases.isEmpty {
                                Text(rule.aliases.joined(separator: " · "))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 3)
                    }
                }
                .padding(24)
                .frame(maxWidth: 560, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(BookPaperBackground())
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(rule.term)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 480, minHeight: 300)
    }
}

struct SpellSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let spell: ContentPack.SpellCard

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox(spell.name) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(spell.level) 环 · \(spell.school)")
                                .font(.callout.weight(.medium))
                            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 3) {
                                row("施法时间", spell.castingTime)
                                row("射程", spell.range)
                                if let components = spell.components { row("成分", components) }
                                row("持续时间", spell.duration)
                                row("专注", spell.concentration ? "是" : "否")
                            }
                            Divider()
                            Text(spell.summary)
                                .font(.body)
                                .lineSpacing(3)
                                .textSelection(.enabled)
                            Text(spell.pageRef)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 3)
                    }
                }
                .padding(24)
                .frame(maxWidth: 600, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(BookPaperBackground())
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(spell.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 360)
    }

    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
        }
    }
}
