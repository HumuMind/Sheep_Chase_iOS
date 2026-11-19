@testable import SheepChaseSceneFeature
import SheepChasePersistence
import XCTest

final class SmokeTests: XCTestCase {
    func testSceneViewCanBeConstructed() {
        _ = SceneDetailView(run: RunRecord(name: "测试"))
    }
}
