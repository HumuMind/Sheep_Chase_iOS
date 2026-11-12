import SheepChaseCore
import SheepChaseUI
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct SourceTextDocument {
    let attributed: NSAttributedString
    let sectionStarts: [Int: NSRange]
}

enum SourceTextDocumentBuilder {
    static func build(title: String, sections: [SourceTextSection]) -> SourceTextDocument {
        let result = NSMutableAttributedString()
        let scale = Theme.textScale
        var starts: [Int: NSRange] = [:]

        let titleStyle = NSMutableParagraphStyle()
        titleStyle.paragraphSpacing = 18 * scale
        titleStyle.lineSpacing = 4 * scale
        result.append(NSAttributedString(
            string: title + "\n",
            attributes: [
                .font: sourceFont(size: 30 * scale, bold: true),
                .foregroundColor: nativeColor(Theme.red),
                .paragraphStyle: titleStyle,
            ]
        ))

        for section in sections {
            starts[section.id] = NSRange(location: result.length, length: 1)

            if let heading = section.heading {
                let headingStyle = NSMutableParagraphStyle()
                headingStyle.paragraphSpacingBefore = section.id == 0 ? 0 : 18 * scale
                headingStyle.paragraphSpacing = 6 * scale
                result.append(NSAttributedString(
                    string: heading + "\n",
                    attributes: [
                        .font: sourceFont(size: 21 * scale, bold: true),
                        .foregroundColor: nativeColor(Theme.red),
                        .paragraphStyle: headingStyle,
                    ]
                ))
            }

            let bodyStyle = NSMutableParagraphStyle()
            bodyStyle.lineSpacing = 7 * scale
            bodyStyle.paragraphSpacing = 6 * scale
            for paragraph in section.paragraphs {
                result.append(NSAttributedString(
                    string: "　　" + paragraph + "\n",
                    attributes: [
                        .font: sourceFont(size: 15 * scale, bold: false),
                        .foregroundColor: nativeColor(Theme.ink),
                        .paragraphStyle: bodyStyle,
                    ]
                ))
            }

            if section.isBox {
                let range = NSRange(location: starts[section.id]?.location ?? 0, length: result.length - (starts[section.id]?.location ?? 0))
                result.addAttribute(.backgroundColor, value: nativeColor(Theme.paperDeep).withAlphaComponent(0.42), range: range)
            }
        }

        let footerStyle = NSMutableParagraphStyle()
        footerStyle.alignment = .center
        footerStyle.paragraphSpacingBefore = 22 * scale
        result.append(NSAttributedString(
            string: "荒野逐羊 · 简体中文版\n",
            attributes: [
                .font: sourceFont(size: 10 * scale, bold: false),
                .foregroundColor: nativeColor(Theme.inkSoft).withAlphaComponent(0.75),
                .paragraphStyle: footerStyle,
            ]
        ))

        return SourceTextDocument(attributed: result, sectionStarts: starts)
    }

    #if os(macOS)
    static func sourceFont(size: CGFloat, bold: Bool) -> NSFont {
        let base = NSFont(name: "Songti SC", size: size) ?? NSFont.systemFont(ofSize: size)
        return bold ? NSFontManager.shared.convert(base, toHaveTrait: .boldFontMask) : base
    }

    static func nativeColor(_ color: Color) -> NSColor {
        NSColor(color)
    }
    #else
    static func sourceFont(size: CGFloat, bold: Bool) -> UIFont {
        let base = UIFont(name: "Songti SC", size: size) ?? UIFont.systemFont(ofSize: size)
        guard bold, let descriptor = base.fontDescriptor.withSymbolicTraits(.traitBold) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }

    static func nativeColor(_ color: Color) -> UIColor {
        UIColor(color)
    }
    #endif
}

struct SourceTextView: View {
    let title: String
    let sections: [SourceTextSection]
    let scrollSection: Int?
    let scrollRequest: Int

    private var document: SourceTextDocument {
        SourceTextDocumentBuilder.build(title: title, sections: sections)
    }

    var body: some View {
        #if os(macOS)
        MacSourceTextView(
            document: document,
            scrollSection: scrollSection,
            scrollRequest: scrollRequest
        )
        #else
        IOSSourceTextView(
            document: document,
            scrollSection: scrollSection,
            scrollRequest: scrollRequest
        )
        #endif
    }
}

#if os(macOS)
private struct MacSourceTextView: NSViewRepresentable {
    let document: SourceTextDocument
    let scrollSection: Int?
    let scrollRequest: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        guard let textView = scroll.documentView as? NSTextView else { return scroll }
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 28, height: 34)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textStorage?.setAttributedString(document.attributed)
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        context.coordinator.textView = textView
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        if textView.textStorage?.string != document.attributed.string {
            textView.textStorage?.setAttributedString(document.attributed)
        }
        guard context.coordinator.lastScrollRequest != scrollRequest,
              let section = scrollSection,
              let range = document.sectionStarts[section]
        else { return }
        context.coordinator.lastScrollRequest = scrollRequest
        DispatchQueue.main.async {
            textView.scrollRangeToVisible(range)
        }
    }

    final class Coordinator {
        weak var textView: NSTextView?
        var lastScrollRequest = -1
    }
}
#else
private struct IOSSourceTextView: UIViewRepresentable {
    let document: SourceTextDocument
    let scrollSection: Int?
    let scrollRequest: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 34, left: 28, bottom: 34, right: 28)
        textView.attributedText = document.attributed
        context.coordinator.textView = textView
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.attributedText?.string != document.attributed.string {
            textView.attributedText = document.attributed
        }
        guard context.coordinator.lastScrollRequest != scrollRequest,
              let section = scrollSection,
              let range = document.sectionStarts[section]
        else { return }
        context.coordinator.lastScrollRequest = scrollRequest
        DispatchQueue.main.async {
            textView.scrollRangeToVisible(range)
        }
    }

    final class Coordinator {
        weak var textView: UITextView?
        var lastScrollRequest = -1
    }
}
#endif
