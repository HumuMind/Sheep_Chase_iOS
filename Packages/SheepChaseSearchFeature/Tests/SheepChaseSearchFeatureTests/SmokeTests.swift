@testable import SheepChaseSearchFeature
import XCTest

final class SmokeTests: XCTestCase {
    func testSearchViewCanBeConstructed() {
        _ = GlobalSearchView(run: nil)
    }
}
