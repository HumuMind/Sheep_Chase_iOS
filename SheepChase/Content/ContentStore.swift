import SheepChaseBattleEngine
import SheepChaseExport
import SheepChasePersistence
import SheepChaseUI
import Foundation
import SheepChaseCore

enum ContentStore {
    static func load() -> ContentPack {
        guard
            let url = Bundle.main.url(forResource: "ContentPack", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let pack = try? JSONDecoder().decode(ContentPack.self, from: data)
        else {
            fatalError("ContentPack.json 缺失或无法解码")
        }
        return pack
    }
}
