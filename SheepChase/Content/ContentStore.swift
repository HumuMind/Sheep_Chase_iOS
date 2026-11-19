import Foundation
import SheepChaseCore

enum ContentStoreError: LocalizedError {
    case missingContentPack
    case unreadableContentPack

    var errorDescription: String? {
        switch self {
        case .missingContentPack:
            "App 内缺少 ContentPack.json。请重新运行 python3 scripts/build_content.py 后重新构建 App。"
        case .unreadableContentPack:
            "ContentPack.json 无法读取或格式不正确。请运行 python3 scripts/build_content.py --check 检查内容包。"
        }
    }
}

enum ContentStore {
    static func load() throws -> ContentPack {
        guard let url = Bundle.main.url(forResource: "ContentPack", withExtension: "json") else {
            throw ContentStoreError.missingContentPack
        }
        guard
            let data = try? Data(contentsOf: url),
            let pack = try? JSONDecoder().decode(ContentPack.self, from: data)
        else {
            throw ContentStoreError.unreadableContentPack
        }
        return pack
    }
}
