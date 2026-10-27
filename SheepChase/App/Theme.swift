import SwiftUI

enum Theme {
    static let ink = Color(red: 0.17, green: 0.13, blue: 0.10)
    static let inkSoft = Color(red: 0.32, green: 0.25, blue: 0.19)
    static let muted = Color(red: 0.49, green: 0.40, blue: 0.33)
    static let red = Color(red: 0.48, green: 0.12, blue: 0.10)
    static let redSoft = Color(red: 0.61, green: 0.23, blue: 0.18)
    static let gold = Color(red: 0.66, green: 0.48, blue: 0.30)
    static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let paperDeep = Color(red: 0.93, green: 0.89, blue: 0.82)
    static let card = Color(red: 0.995, green: 0.98, blue: 0.95)
    static let line = Color(red: 0.86, green: 0.80, blue: 0.71)
    static let green = Color(red: 0.30, green: 0.42, blue: 0.32)
    static let amber = Color(red: 0.60, green: 0.40, blue: 0.18)

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Songti SC", size: size).weight(weight)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static var background: some View {
        LinearGradient(
            colors: [Color(red: 0.25, green: 0.18, blue: 0.13), Color(red: 0.15, green: 0.10, blue: 0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct BookGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)
                .foregroundStyle(Theme.ink)
            Rectangle()
                .fill(Theme.line.opacity(0.55))
                .frame(height: 0.5)
            configuration.content
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BookPaperBackground: View {
    var body: some View {
        GeometryReader { proxy in
            Image("Parchment")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay(Color(red: 0.99, green: 0.965, blue: 0.91).opacity(0.22))
                .overlay(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.13, blue: 0.07).opacity(0.16),
                            Color.clear,
                            Color.clear,
                            Color(red: 0.22, green: 0.13, blue: 0.07).opacity(0.12),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    LinearGradient(
                        colors: [
                            Color(red: 0.22, green: 0.13, blue: 0.07).opacity(0.10),
                            Color.clear,
                            Color.clear,
                            Color(red: 0.22, green: 0.13, blue: 0.07).opacity(0.08),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .ignoresSafeArea()
    }
}

extension View {
    func cardStyle(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func panelStyle() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [Theme.paper, Theme.paperDeep.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

extension View {
    @ViewBuilder
    func bookPaperSurface() -> some View {
        #if os(iOS)
        self.background { BookPaperBackground() }
        #else
        self
        #endif
    }

    @ViewBuilder
    func themedToolbarBackground() -> some View {
        #if os(macOS)
        self.toolbarBackground(Theme.paper, for: .windowToolbar)
        #else
        self
            .toolbarBackground(Theme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }

    @ViewBuilder
    func macNavigationSubtitle(_ text: String) -> some View {
        #if os(macOS)
        self.navigationSubtitle(text)
        #else
        self
        #endif
    }
}

extension String {
    var singleLineSpaced: String {
        replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Date {
    var shortRelative: String {
        let delta = Date().timeIntervalSince(self)
        if delta < 60 { return "刚刚" }
        if delta < 3600 { return "\(Int(delta / 60)) 分钟前" }
        if delta < 86400 { return "\(Int(delta / 3600)) 小时前" }
        return formatted(date: .abbreviated, time: .omitted)
    }
}
