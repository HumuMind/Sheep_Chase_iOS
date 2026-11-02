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
    @State private var selectedSectionID: Int?
    @State private var scrollTarget: Int?

    public var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                #if os(macOS)
                tableOfContents
                Divider()
                #endif
                sourceScroll
            }
            #if !os(macOS)
            tableOfContentsMenu
                .padding(18)
            #endif
        }
        .background(Theme.sheetBackground)
        .ignoresSafeArea()
        .dismissOnBackgroundClick { dismiss() }
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

    private var pageMaxWidth: CGFloat {
        #if os(macOS)
        600
        #else
        BookSheetMetrics.pageWidth
        #endif
    }

    private var sourceScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(scene.title)
                    .bookSerif(30, weight: .semibold)
                    .foregroundStyle(Theme.red)
                    .padding(.bottom, 20)

                ForEach(sections) { section in
                    sectionView(section)
                        .id(section.id)
                }

                pageFooter
            }
            .scrollTargetLayout()
            .padding(.horizontal, 28)
            .padding(.top, 48)
            .padding(.bottom, 36)
            .frame(maxWidth: pageMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Theme.readingPaper)
            .overlay(Rectangle().stroke(Theme.line.opacity(0.55), lineWidth: 0.5))
            .padding(.vertical, 16)
        }
        .scrollPosition(id: $scrollTarget, anchor: UnitPoint(x: 0.5, y: 0.12))
        .scrollIndicators(.visible)
    }

    #if os(macOS)
    private var tableOfContents: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "list.bullet")
                    .foregroundStyle(Theme.red)
                Text("目录")
                    .bookSerif(18, weight: .semibold)
                    .foregroundStyle(Theme.red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(sections) { section in
                        Button {
                            selectedSectionID = section.id
                            withAnimation(.easeInOut(duration: 0.2)) {
                                scrollTarget = section.id
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 6) {
                                Rectangle()
                                    .fill(selectedSectionID == section.id ? Theme.red : .clear)
                                    .frame(width: 2)
                                Text(section.heading ?? scene.title)
                                    .bookSerif(12, weight: selectedSectionID == section.id ? .semibold : .regular)
                                    .foregroundStyle(selectedSectionID == section.id ? Theme.red : Theme.inkSoft)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 5)
                            .padding(.trailing, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 170)
        .background(Theme.readingPaper)
    }
    #endif

    #if !os(macOS)
    private var tableOfContentsMenu: some View {
        Menu {
            ForEach(sections) { section in
                Button(section.heading ?? scene.title) {
                    selectedSectionID = section.id
                    withAnimation(.easeInOut(duration: 0.2)) {
                        scrollTarget = section.id
                    }
                }
            }
        } label: {
            Label("目录", systemImage: "list.bullet")
                .font(.callout)
        }
        .menuStyle(.borderlessButton)
        .padding(8)
        .background(Theme.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 6))
    }
    #endif

    private func sectionView(_ section: SourceTextSection) -> some View {
        Group {
            if let heading = section.heading,
               let monster = store.content.monsters.first(where: { $0.name == heading }) {
                MonsterStatBlockCard(monster: monster)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if let heading = section.heading {
                        Text(heading)
                            .bookSerif(21, weight: .semibold)
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
                    .bookSerif(15, weight: .semibold)
                    .foregroundStyle(Theme.ink)
                if !answer.isEmpty {
                    Text("　　\(answer)")
                        .bookSerif(15)
                        .lineSpacing(7)
                        .foregroundStyle(Theme.ink)
                }
            }
            .padding(.bottom, 7)
        } else {
            Text("　　\(paragraph)")
                .bookSerif(15)
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
                .bookSerif(10)
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
