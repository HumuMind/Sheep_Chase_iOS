import SwiftUI
import SheepChaseCore

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

public struct HandoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let handout: ContentPack.Handout
    let asset: ContentPack.Asset?
    let annotation: DMAnnotation?
    let onAnnotationSave: ((String, DMAnnotationMode) -> Void)?
    let onAnnotationDelete: (() -> Void)?

    public init(
        handout: ContentPack.Handout,
        asset: ContentPack.Asset?,
        annotation: DMAnnotation? = nil,
        onAnnotationSave: ((String, DMAnnotationMode) -> Void)? = nil,
        onAnnotationDelete: (() -> Void)? = nil
    ) {
        self.handout = handout
        self.asset = asset
        self.annotation = annotation
        self.onAnnotationSave = onAnnotationSave
        self.onAnnotationDelete = onAnnotationDelete
    }

    public var body: some View {
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
                       let image = SheepChaseImages.image(forAssetID: imageAssetID) {
                        GroupBox("图片") {
                            image
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

                    if let onAnnotationSave, let onAnnotationDelete {
                        DMAnnotationEditor(
                            subject: handout.title,
                            annotation: annotation,
                            onSave: onAnnotationSave,
                            onDelete: onAnnotationDelete
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Theme.sheetBackground)
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(handout.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
    }
}

public struct ItemSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ContentPack.Item
    let annotation: DMAnnotation?
    let onAnnotationSave: ((String, DMAnnotationMode) -> Void)?
    let onAnnotationDelete: (() -> Void)?

    public init(
        item: ContentPack.Item,
        annotation: DMAnnotation? = nil,
        onAnnotationSave: ((String, DMAnnotationMode) -> Void)? = nil,
        onAnnotationDelete: (() -> Void)? = nil
    ) {
        self.item = item
        self.annotation = annotation
        self.onAnnotationSave = onAnnotationSave
        self.onAnnotationDelete = onAnnotationDelete
    }

    public var body: some View {
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

                    if let onAnnotationSave, let onAnnotationDelete {
                        DMAnnotationEditor(
                            subject: item.name,
                            annotation: annotation,
                            onSave: onAnnotationSave,
                            onDelete: onAnnotationDelete
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: BookSheetMetrics.compactPageWidth, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Theme.sheetBackground)
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(item.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
    }
}

public struct RuleSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let rule: ContentPack.RuleCard
    let annotation: DMAnnotation?
    let onAnnotationSave: ((String, DMAnnotationMode) -> Void)?
    let onAnnotationDelete: (() -> Void)?

    public init(
        rule: ContentPack.RuleCard,
        annotation: DMAnnotation? = nil,
        onAnnotationSave: ((String, DMAnnotationMode) -> Void)? = nil,
        onAnnotationDelete: (() -> Void)? = nil
    ) {
        self.rule = rule
        self.annotation = annotation
        self.onAnnotationSave = onAnnotationSave
        self.onAnnotationDelete = onAnnotationDelete
    }

    public var body: some View {
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

                    if let onAnnotationSave, let onAnnotationDelete {
                        DMAnnotationEditor(
                            subject: rule.term,
                            annotation: annotation,
                            onSave: onAnnotationSave,
                            onDelete: onAnnotationDelete
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: BookSheetMetrics.compactPageWidth, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Theme.sheetBackground)
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(rule.term)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
    }
}

public struct SpellSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let spell: ContentPack.SpellCard
    let annotation: DMAnnotation?
    let onAnnotationSave: ((String, DMAnnotationMode) -> Void)?
    let onAnnotationDelete: (() -> Void)?

    public init(
        spell: ContentPack.SpellCard,
        annotation: DMAnnotation? = nil,
        onAnnotationSave: ((String, DMAnnotationMode) -> Void)? = nil,
        onAnnotationDelete: (() -> Void)? = nil
    ) {
        self.spell = spell
        self.annotation = annotation
        self.onAnnotationSave = onAnnotationSave
        self.onAnnotationDelete = onAnnotationDelete
    }

    public var body: some View {
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

                    if let onAnnotationSave, let onAnnotationDelete {
                        DMAnnotationEditor(
                            subject: spell.name,
                            annotation: annotation,
                            onSave: onAnnotationSave,
                            onDelete: onAnnotationDelete
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: BookSheetMetrics.compactPageWidth, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Theme.sheetBackground)
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle(spell.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
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
