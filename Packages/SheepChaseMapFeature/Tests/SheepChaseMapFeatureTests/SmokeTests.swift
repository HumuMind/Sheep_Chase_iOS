@testable import SheepChaseMapFeature
import SheepChasePersistence
import XCTest

final class SmokeTests: XCTestCase {
    func testMapViewCanBeConstructed() {
        _ = MapView(run: RunRecord(name: "测试"))
    }
}
