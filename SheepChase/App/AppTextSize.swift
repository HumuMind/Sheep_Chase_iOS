import SwiftUI

enum AppTextSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case xLarge
    case accessibility

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small: "小"
        case .medium: "中"
        case .large: "标准"
        case .xLarge: "大"
        case .accessibility: "特大"
        }
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .small: .small
        case .medium: .medium
        case .large: .large
        case .xLarge: .xLarge
        case .accessibility: .accessibility2
        }
    }
}
