import XCTest
import SheepChasePersistence
@testable import SheepChaseSceneFeature

final class SmokeTests: XCTestCase {
    func testSceneViewCanBeConstructed() {
        _ = SceneDetailView(run: RunRecord(name: "测试"))
    }
}
