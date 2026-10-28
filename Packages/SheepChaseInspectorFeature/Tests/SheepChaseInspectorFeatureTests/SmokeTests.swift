import SwiftUI
import XCTest
import SheepChasePersistence
@testable import SheepChaseInspectorFeature

final class SmokeTests: XCTestCase {
    func testInspectorCanBeConstructed() {
        let run = RunRecord(name: "测试")
        _ = InspectorView(run: run, showAddPlayer: .constant(false))
        _ = AddPlayerSheet(run: run)
        _ = SafetySheet(run: run)
        _ = SessionLogView(run: run)
    }
}
