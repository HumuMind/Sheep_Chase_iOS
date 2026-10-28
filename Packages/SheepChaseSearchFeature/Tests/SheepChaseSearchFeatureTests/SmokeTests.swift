import XCTest
@testable import SheepChaseSearchFeature

final class SmokeTests: XCTestCase {
    func testSearchViewCanBeConstructed() {
        _ = GlobalSearchView(run: nil)
    }
}
