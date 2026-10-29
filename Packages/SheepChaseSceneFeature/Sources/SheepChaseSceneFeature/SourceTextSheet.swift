import SheepChaseCore
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

public struct SourceTextSheet: View {
    public init(scene: ContentPack.AdventureScene) {
        self.scene = scene
        self.sections = SourceTextParser.parse(scene.dmText ?? "")
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(RunStore.self) private var store
    private let scene: ContentPack.AdventureScene
    private let sections: [SourceTextSection]

    public var body: some View {
        ZStack {
            BookPaperBackground()
                .environment(\.colorScheme, .light)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(scene.title)
                        .font(Theme.serif(30, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .padding(.bottom, 20)

                    ForEach(sections) { section in
                        sectionView(section)
                    }

                    pageFooter
                }
                .padding(.horizontal, 40)
                .padding(.top, 48)
                .padding(.bottom, 36)
                .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(red: 0.99, green: 0.97, blue: 0.92).opacity(0.35))
            }
            .scrollIndicators(.visible)
        }
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Button("完成") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .padding(18)
        }
        .environment(\.colorScheme, .light)
        .tint(Theme.red)
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
    }

    private func sectionView(_ section: SourceTextSection) -> some View {
        Group {
            if let heading = section.heading,
               let monster = store.content.monsters.first(where: { $0.name == heading }) {
                MonsterStatBlockCard(monster: monster)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if let heading = section.heading {
                        Text(heading)
                            .font(Theme.serif(21, weight: .semibold))
                            .foregroundStyle(Theme.red)
                            .padding(.top, section.id == 0 ? 0 : 22)
                            .padding(.bottom, 2)
                    }

                    ForEach(section.paragraphs.indices, id: \.self) { index in
                        paragraphView(section.paragraphs[index])
                    }
                }
            }
        }
        .padding(section.isBox ? 16 : 0)
        .background(
            section.isBox ? Color(red: 0.91, green: 0.86, blue: 0.76).opacity(0.42) : .clear
        )
        .overlay(alignment: .leading) {
            if section.isBox {
                Rectangle()
                    .fill(Theme.red.opacity(0.8))
                    .frame(width: 3)
            }
        }
        .padding(.bottom, section.isBox ? 14 : 4)
    }

    @ViewBuilder
    private func paragraphView(_ paragraph: String) -> some View {
        if let questionEnd = paragraph.firstIndex(of: "？"), paragraph[..<questionEnd].count < 60 {
            let question = String(paragraph[...questionEnd])
            let answer = String(paragraph[paragraph.index(after: questionEnd)...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            VStack(alignment: .leading, spacing: 2) {
                Text(question)
                    .font(Theme.serif(15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                if !answer.isEmpty {
                    Text("　　\(answer)")
                        .font(Theme.serif(15))
                        .lineSpacing(7)
                        .foregroundStyle(Theme.ink)
                }
            }
            .padding(.bottom, 7)
        } else {
            Text("　　\(paragraph)")
                .font(Theme.serif(15))
                .lineSpacing(7)
                .foregroundStyle(Theme.ink)
                .textSelection(.enabled)
                .padding(.bottom, 7)
        }
    }

    private var pageFooter: some View {
        HStack {
            Spacer()
            Text("荒野逐羊 · 简体中文版")
                .font(Theme.serif(10))
                .foregroundStyle(Theme.inkSoft.opacity(0.75))
            Spacer()
        }
        .padding(.top, 28)
        .padding(.bottom, 8)
    }
}

private struct SourceTextSection: Identifiable {
    let id: Int
    let heading: String?
    let paragraphs: [String]
    let isBox: Bool
}

private enum SourceTextParser {
    static func parse(_ text: String) -> [SourceTextSection] {
        let rawBlocks = text
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var sections: [SourceTextSection] = []
        var currentHeading: String?
        var currentParagraphs: [String] = []

        func appendCurrent() {
            guard currentHeading != nil || !currentParagraphs.isEmpty else { return }
            let heading = currentHeading
            let boxed = heading == "夏恩布莱特的故事" || heading == "疑难解答"
            sections.append(SourceTextSection(
                id: sections.count,
                heading: heading,
                paragraphs: currentParagraphs,
                isBox: boxed
            ))
        }

        for block in rawBlocks {
            if block.hasPrefix("【"), block.hasSuffix("】"), block.count > 2 {
                appendCurrent()
                currentHeading = String(block.dropFirst().dropLast())
                currentParagraphs = []
            } else {
                currentParagraphs.append(block)
            }
        }
        appendCurrent()
        return sections
    }
}
