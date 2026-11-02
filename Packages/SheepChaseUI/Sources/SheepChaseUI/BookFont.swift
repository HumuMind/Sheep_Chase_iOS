import SwiftUI

private struct BookSerifModifier: ViewModifier {
    @AppStorage("appTextSize") private var appTextSize = AppTextSize.large.rawValue
    let size: CGFloat
    let weight: Font.Weight
    let monospaced: Bool

    func body(content: Content) -> some View {
        let scale = (AppTextSize(rawValue: appTextSize) ?? .large).scale
        let font = Font.custom("Songti SC", size: size * scale).weight(weight)
        content.font(monospaced ? font.monospacedDigit() : font)
    }
}

private struct BookUIModifier: ViewModifier {
    @AppStorage("appTextSize") private var appTextSize = AppTextSize.large.rawValue
    let size: CGFloat
    let weight: Font.Weight
    let monospaced: Bool

    func body(content: Content) -> some View {
        let scale = (AppTextSize(rawValue: appTextSize) ?? .large).scale
        let font = Font.system(size: size * scale, weight: weight, design: .default)
        content.font(monospaced ? font.monospacedDigit() : font)
    }
}

public extension View {
    func bookSerif(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        monospaced: Bool = false
    ) -> some View {
        modifier(BookSerifModifier(size: size, weight: weight, monospaced: monospaced))
    }

    func bookUI(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        monospaced: Bool = false
    ) -> some View {
        modifier(BookUIModifier(size: size, weight: weight, monospaced: monospaced))
    }
}
