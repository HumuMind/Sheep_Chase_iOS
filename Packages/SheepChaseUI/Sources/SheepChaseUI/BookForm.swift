import SwiftUI

public struct BookFormSheet<Content: View>: View {
    private let title: String
    private let primaryTitle: String
    private let primaryDisabled: Bool
    private let deleteTitle: String?
    private let onCancel: () -> Void
    private let onDelete: (() -> Void)?
    private let onPrimary: () -> Void
    private let content: Content

    public init(
        title: String,
        primaryTitle: String = "保存",
        primaryDisabled: Bool = false,
        deleteTitle: String? = nil,
        onCancel: @escaping () -> Void,
        onDelete: (() -> Void)? = nil,
        onPrimary: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.primaryTitle = primaryTitle
        self.primaryDisabled = primaryDisabled
        self.deleteTitle = deleteTitle
        self.onCancel = onCancel
        self.onDelete = onDelete
        self.onPrimary = onPrimary
        self.content = content()
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Button("取消", action: onCancel)
                            .buttonStyle(.borderless)
                            .foregroundStyle(Theme.inkSoft)

                        Spacer()

                        if let deleteTitle, let onDelete {
                            Button(deleteTitle, role: .destructive, action: onDelete)
                                .buttonStyle(.borderless)
                        }

                        Button(primaryTitle, action: onPrimary)
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.red)
                            .disabled(primaryDisabled)
                            .keyboardShortcut(.defaultAction)
                    }
                    .font(Theme.serif(13))

                    Divider()
                        .opacity(0.45)

                    Text(title)
                        .font(Theme.serif(28, weight: .semibold))
                        .foregroundStyle(Theme.red)
                        .padding(.top, 2)
                        .padding(.bottom, 2)

                    content
                }
                .padding(28)
                .frame(maxWidth: .infinity, minHeight: max(430, proxy.size.height), alignment: .topLeading)
            }
        }
        .background(Theme.readingPaper)
        .dismissOnBackgroundClick(onCancel)
        .environment(\.colorScheme, .light)
        .tint(Theme.red)
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
    }
}

public struct BookFormSection<Content: View>: View {
    private let title: String
    private let content: Content

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.serif(18, weight: .semibold))
                .foregroundStyle(Theme.red)
            Rectangle()
                .fill(Theme.line.opacity(0.55))
                .frame(height: 0.5)
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
        .padding(.bottom, 4)
    }
}

public struct BookTextField: View {
    private let label: String
    @Binding private var text: String

    public init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.serif(11))
                .foregroundStyle(.secondary)
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(Theme.serif(15))
                .selectAllOnFocus()
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(Theme.paperDeep.opacity(0.35), in: RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.line.opacity(0.65), lineWidth: 1)
                )
        }
    }
}

public struct BookTextEditor: View {
    private let placeholder: String
    @Binding private var text: String
    private let minHeight: CGFloat

    public init(_ placeholder: String, text: Binding<String>, minHeight: CGFloat = 90) {
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(Theme.serif(14))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 10)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $text)
                .font(Theme.serif(15))
                .scrollContentBackground(.hidden)
                .padding(6)
                .frame(minHeight: minHeight)
        }
        .background(Theme.paperDeep.opacity(0.28), in: RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Theme.line.opacity(0.65), lineWidth: 1)
        )
    }
}

public struct BookNumberField: View {
    private let label: String
    @Binding private var value: Int
    @State private var text: String

    public init(_ label: String, value: Binding<Int>) {
        self.label = label
        self._value = value
        _text = State(initialValue: String(value.wrappedValue))
    }

    public var body: some View {
        HStack {
            Text(label)
                .font(Theme.serif(13))
                .foregroundStyle(Theme.inkSoft)
            Spacer()
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .font(Theme.serif(14).monospacedDigit())
                .multilineTextAlignment(.trailing)
                .frame(width: 66)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Theme.paperDeep.opacity(0.35), in: RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Theme.line.opacity(0.55), lineWidth: 1)
                )
                .selectAllOnFocus()
                .onChange(of: text) { _, newValue in
                    if let parsed = Int(newValue) {
                        value = parsed
                    }
                }
                .onChange(of: value) { _, newValue in
                    if Int(text) != newValue {
                        text = String(newValue)
                    }
                }
        }
    }
}

public enum BookSheetMetrics {
    #if os(macOS)
    public static let minWidth: CGFloat = 820
    public static let minHeight: CGFloat = 640
    public static let idealWidth: CGFloat = 900
    public static let idealHeight: CGFloat = 720
    public static let pageWidth: CGFloat = 760
    public static let compactPageWidth: CGFloat = 700
    #else
    public static let minWidth: CGFloat = 520
    public static let minHeight: CGFloat = 420
    public static let idealWidth: CGFloat = 640
    public static let idealHeight: CGFloat = 560
    public static let pageWidth: CGFloat = 640
    public static let compactPageWidth: CGFloat = 600
    #endif
}
