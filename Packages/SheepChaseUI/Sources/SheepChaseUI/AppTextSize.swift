import SwiftUI

public enum AppTextSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case xLarge
    case accessibility

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .small: "小"
        case .medium: "中"
        case .large: "标准"
        case .xLarge: "大"
        case .accessibility: "特大"
        }
    }

    public var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .xLarge
        case .accessibility: .accessibility2
        }
    }
}
