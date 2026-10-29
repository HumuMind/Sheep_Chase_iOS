import SheepChaseCore
import SheepChaseUI
import SwiftUI

public struct AdventureGuideView: View {
    public init(content: ContentPack) {
        self.content = content
    }

    @Environment(\.dismiss) private var dismiss
    private let content: ContentPack

    private var sections: [ContentPack.Adventure.GuideSection] {
        content.adventure.guide ?? []
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    intro
                    if sections.isEmpty {
                        ContentUnavailableView(
                            "暂无导读",
                            systemImage: "book.closed",
                            description: Text("内容包没有提供 DM 导读。")
                        )
                    } else {
                        ForEach(sections) { section in
                            guideSection(section)
                        }
                    }
                    footer
                }
                .padding(28)
                .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("DM 导读")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .tint(Theme.red)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 14) {
                SheepChaseImages.cover
                    .resizable()
                    .scaledToFill()
                    .frame(width: 62, height: 82)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.line, lineWidth: 1))
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.adventure.title)
                        .font(Theme.serif(28, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(content.adventure.level.min)–\(content.adventure.level.max) 级 · \(content.adventure.players.min)–\(content.adventure.players.max) 人 · 约 \(content.adventure.durationMinutes / 60) 小时")
                        .font(.callout)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }

            Text(content.adventure.summary)
                .font(.body)
                .lineSpacing(4)
                .foregroundStyle(Theme.inkSoft)
                .textSelection(.enabled)

            if !content.adventure.contentWarnings.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(Theme.red)
                    Text("内容提示：\(content.adventure.contentWarnings.joined(separator: "、"))")
                        .font(.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 2)
            }
        }
        .padding(.bottom, 4)
    }

    private func guideSection(_ section: ContentPack.Adventure.GuideSection) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if let kicker = section.kicker, !kicker.isEmpty {
                    Text(kicker)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.red)
                }
                Text(section.title)
                    .font(Theme.serif(21, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(section.body)
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(Theme.inkSoft)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let sourceRef = section.sourceRef, !sourceRef.isEmpty {
                    Text(sourceRef)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 3)
        }
    }

    private var footer: some View {
        Text("本导读整理自《荒野逐羊》简体中文版前置说明与主持建议；角色与规则细节可从场景页和速查入口继续查阅。")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
    }
}
