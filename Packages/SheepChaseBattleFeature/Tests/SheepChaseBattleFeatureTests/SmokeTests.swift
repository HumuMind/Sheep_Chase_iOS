import XCTest
import SheepChasePersistence
@testable import SheepChaseBattleFeature

final class SmokeTests: XCTestCase {
    func testBattleViewsCanBeConstructed() {
        let run = RunRecord(name: "测试")
        _ = BattleCenterView(run: run)
        _ = BattleInspector(run: run)
    }
}
