import SwiftUI

public enum Theme {
    public static let ink = Color(red: 0.17, green: 0.13, blue: 0.10)
    public static let inkSoft = Color(red: 0.32, green: 0.25, blue: 0.19)
    public static let muted = Color(red: 0.49, green: 0.40, blue: 0.33)
    public static let red = Color(red: 0.48, green: 0.12, blue: 0.10)
    public static let redSoft = Color(red: 0.61, green: 0.23, blue: 0.18)
    public static let gold = Color(red: 0.66, green: 0.48, blue: 0.30)
    public static let paper = Color(red: 0.98, green: 0.96, blue: 0.92)
    public static let paperDeep = Color(red: 0.93, green: 0.89, blue: 0.82)
    public static let card = Color(red: 0.995, green: 0.98, blue: 0.95)
    public static let readingPaper = Color(red: 0.985, green: 0.968, blue: 0.925)
    public static let line = Color(red: 0.86, green: 0.80, blue: 0.71)
    public static let green = Color(red: 0.30, green: 0.42, blue: 0.32)
    public static let amber = Color(red: 0.60, green: 0.40, blue: 0.18)
    public static let darkDesk = Color(red: 0.10, green: 0.075, blue: 0.06)
    public static let darkDeskToolbar = Color(red: 0.14, green: 0.105, blue: 0.08)

    public static var textScale: CGFloat {
        let raw = UserDefaults.standard.string(forKey: "appTextSize") ?? AppTextSize.large.rawValue
        return (AppTextSize(rawValue: raw) ?? .large).scale
    }

    public static var background: some View {
        LinearGradient(
            colors: [Color(red: 0.25, green: 0.18, blue: 0.13), Color(red: 0.15, green: 0.10, blue: 0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

public struct BookGroupBoxStyle: GroupBoxStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .bookUI(13, weight: .semibold)
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

public extension Theme {
    static var sheetBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemGroupedBackground)
        #endif
    }
}

public struct BookPaperBackground: View {
    public init() {}

    @Environment(\.colorScheme) private var colorScheme

    public var body: some View {
        GeometryReader { proxy in
            if colorScheme == .dark {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.115, blue: 0.08),
                            Theme.darkDesk,
                            Color(red: 0.06, green: 0.045, blue: 0.035),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image("Parchment", bundle: .module)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .saturation(0.25)
                        .brightness(-0.60)
                        .opacity(0.28)
                        .blendMode(.softLight)
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.35),
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(0.28),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            } else {
                Image("Parchment", bundle: .module)
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
        }
        .ignoresSafeArea()
    }
}

extension View {
    public func cardStyle(padding: CGFloat = 14) -> some View {
        self
            .padding(padding)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    public func panelStyle() -> some View {
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
    public func readingPage() -> some View {
        self
            .background(Theme.readingPaper)
            .overlay(
                Rectangle()
                    .stroke(Theme.line.opacity(0.55), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
            .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    public func bookPaperSurface() -> some View {
        #if os(iOS)
        self.background { BookPaperBackground() }
        #else
        self
        #endif
    }

    public func themedToolbarBackground() -> some View {
        modifier(ThemedToolbarBackgroundModifier())
    }

    @ViewBuilder
    public func compactNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    public func macNavigationSubtitle(_ text: String) -> some View {
        #if os(macOS)
        self.navigationSubtitle(text)
        #else
        self
        #endif
    }
}

extension String {
    public var singleLineSpaced: String {
        replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Date {
    public var shortRelative: String {
        let delta = Date().timeIntervalSince(self)
        if delta < 60 { return "刚刚" }
        if delta < 3600 { return "\(Int(delta / 60)) 分钟前" }
        if delta < 86400 { return "\(Int(delta / 3600)) 小时前" }
        return formatted(date: .abbreviated, time: .omitted)
    }
}


private struct ThemedToolbarBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var color: Color {
        colorScheme == .dark ? Theme.darkDeskToolbar : Theme.paper
    }

    func body(content: Content) -> some View {
        #if os(macOS)
        content.toolbarBackground(color, for: .windowToolbar)
        #else
        content
            .toolbarBackground(color, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        #endif
    }
}
