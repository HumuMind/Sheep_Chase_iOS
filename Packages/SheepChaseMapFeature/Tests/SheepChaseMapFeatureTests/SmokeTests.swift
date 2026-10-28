import XCTest
import SheepChasePersistence
@testable import SheepChaseMapFeature

final class SmokeTests: XCTestCase {
    func testMapViewCanBeConstructed() {
        _ = MapView(run: RunRecord(name: "测试"))
    }
}
