@testable import SheepChaseBattleFeature
import SheepChasePersistence
import XCTest

final class SmokeTests: XCTestCase {
    func testBattleViewsCanBeConstructed() {
        let run = RunRecord(name: "测试")
        _ = BattleCenterView(run: run)
        _ = BattleInspector(run: run)
    }
}
