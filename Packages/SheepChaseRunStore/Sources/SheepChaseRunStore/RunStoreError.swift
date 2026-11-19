import Foundation

public enum RunStoreError: LocalizedError {
    case persistenceFailed

    public var errorDescription: String? {
        switch self {
        case .persistenceFailed:
            "开团数据保存失败，请检查存储空间后重试。"
        }
    }
}
