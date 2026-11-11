import SwiftUI

public struct AutoGrowingTextEditor: View {
    @Binding private var text: String
    private let placeholder: String
    private let minHeight: CGFloat

    @State private var measuredHeight: CGFloat = 0
    @State private var measuredWidth: CGFloat = 0

    public init(_ placeholder: String, text: Binding<String>, minHeight: CGFloat = 44) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    public var body: some View {
        TextEditor(text: $text)
            .bookUI(11)
            .lineSpacing(2)
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .frame(height: max(minHeight, measuredHeight + 18))
            .background(alignment: .topLeading) {
                Text(text.isEmpty ? " " : text)
                    .bookUI(11)
                    .lineSpacing(2)
                    .frame(width: max(0, measuredWidth - 10), alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: AutoGrowingTextHeightKey.self,
                                value: proxy.size.height
                            )
                        }
                    )
            }
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { measuredWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { _, width in
                            measuredWidth = width
                        }
                }
            )
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .bookUI(11)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
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
