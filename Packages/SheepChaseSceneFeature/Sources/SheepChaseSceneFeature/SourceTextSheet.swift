import SheepChaseCore
import SheepChaseUI
import SwiftUI

public struct SourceTextSheet: View {
    public init(scene: ContentPack.AdventureScene) {
        self.scene = scene
        self.sections = SourceTextParser.parse(scene.dmText ?? "")
    }

    @Environment(\.dismiss) private var dismiss
    private let scene: ContentPack.AdventureScene
    private let sections: [SourceTextSection]
    @State private var selectedSectionID: Int?
    @State private var scrollSection: Int?
    @State private var scrollRequest = 0

    public var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 0) {
                #if os(macOS)
                tableOfContents
                Divider()
                #endif
                SourceTextView(
                    title: scene.title,
                    sections: sections,
                    scrollSection: scrollSection,
                    scrollRequest: scrollRequest
                )
                .frame(maxWidth: pageMaxWidth, maxHeight: .infinity)
                .background(Theme.readingPaper)
                .overlay(Rectangle().stroke(Theme.line.opacity(0.55), lineWidth: 0.5))
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                            jump(to: section)
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
                    jump(to: section)
                }
            }
        } label: {
            Label("目录", systemImage: "list.bullet")
                .bookUI(12)
        }
        .menuStyle(.borderlessButton)
        .padding(8)
        .background(Theme.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 6))
    }
    #endif

    private func jump(to section: SourceTextSection) {
        selectedSectionID = section.id
        scrollSection = section.id
        scrollRequest += 1
    }
}

struct SourceTextSection: Identifiable {
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
