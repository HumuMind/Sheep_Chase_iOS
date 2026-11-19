@testable import SheepChaseRunShellFeature
import SheepChasePersistence
import XCTest

final class SmokeTests: XCTestCase {
    func testRunViewCanBeConstructed() {
        _ = RunView(run: RunRecord(name: "测试"))
    }
}
