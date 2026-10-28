import Foundation
import XCTest
import SheepChaseCore
@testable import SheepChaseGuideFeature

final class SmokeTests: XCTestCase {
    private var content: ContentPack {
        get throws {
            var root = URL(fileURLWithPath: #filePath)
            for _ in 0..<5 { root.deleteLastPathComponent() }
            let url = root.appendingPathComponent("SheepChase/Resources/ContentPack.json")
            return try JSONDecoder().decode(ContentPack.self, from: Data(contentsOf: url))
        }
    }

    func testGuideHasFrontMatterSections() throws {
        let content = try content
        XCTAssertEqual(content.adventure.guide?.count, 8)
        XCTAssertTrue(content.adventure.guide?.contains { $0.id == "how-to-use" } == true)
        _ = AdventureGuideView(content: content)
    }
}
