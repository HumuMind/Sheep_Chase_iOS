import XCTest
import SwiftUI
@testable import SheepChaseUI

final class UITests: XCTestCase {
    func testTextSizeCasesAndTitles() {
        XCTAssertEqual(AppTextSize.allCases.count, 5)
        XCTAssertEqual(AppTextSize.small.title, "小")
        XCTAssertEqual(AppTextSize.large.dynamicTypeSize, .large)
        XCTAssertEqual(AppTextSize.accessibility.dynamicTypeSize, .accessibility2)
    }

    func testKnownImageAssetsResolve() {
        XCTAssertNotNil(SheepChaseImages.image(forAssetID: "cover"))
        XCTAssertNotNil(SheepChaseImages.image(forAssetID: "map-treehouse"))
        XCTAssertNotNil(SheepChaseImages.image(forAssetID: "sheep-illustration"))
        XCTAssertNil(SheepChaseImages.image(forAssetID: "missing"))
    }
}
