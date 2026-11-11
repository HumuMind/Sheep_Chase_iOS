import SwiftUI

public struct AutoGrowingTextEditor: View {
    @Binding private var text: String
    private let placeholder: String
    private let minHeight: CGFloat

    @State private var measuredHeight: CGFloat = 0

    public init(_ placeholder: String, text: Binding<String>, minHeight: CGFloat = 44) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            Text(text.isEmpty ? " " : text + "\n")
                .bookUI(11)
                .lineSpacing(2)
                .padding(.horizontal, 5)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(0)
                .allowsHitTesting(false)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: AutoGrowingTextHeightKey.self,
                            value: proxy.size.height
                        )
                    }
                )

            if text.isEmpty {
                Text(placeholder)
                    .bookUI(11)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .bookUI(11)
                .lineSpacing(2)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
        }
        .frame(height: max(minHeight, measuredHeight + 4))
        .background(Theme.paperDeep.opacity(0.22), in: RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Theme.line.opacity(0.5), lineWidth: 1)
        )
        .onPreferenceChange(AutoGrowingTextHeightKey.self) { height in
            measuredHeight = height
        }
    }
}

private struct AutoGrowingTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
