import XCTest
import SheepChasePersistence
@testable import SheepChaseRunShellFeature

final class SmokeTests: XCTestCase {
    func testRunViewCanBeConstructed() {
        _ = RunView(run: RunRecord(name: "测试"))
    }
}
