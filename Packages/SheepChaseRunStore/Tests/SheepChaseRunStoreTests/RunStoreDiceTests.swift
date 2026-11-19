import XCTest
import SheepChaseCore
@testable import SheepChaseRunStore

final class RunStoreDiceTests: RunStoreTestCase {
    @MainActor
    func testRollDiceRecordsHistoryAndBattleLog() throws {
        let store = try makeStore()
        store.createRun(name: "骰子团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }
        store.openBattleSetup(for: run)

        let expression = DiceExpression(terms: [DiceTerm(count: 2, sides: 6)], modifier: 3)
        let roll = store.rollDice(
            expression,
            command: "2d6+3",
            subject: "古兹",
            logToBattle: true,
            in: run
        ) { _ in 4 }

        XCTAssertEqual(roll.total, 11)
        XCTAssertEqual(store.diceHistory(in: run).first?.command, "2d6+3")
        XCTAssertEqual(store.diceHistory(in: run).first?.subject, "古兹")
        XCTAssertEqual(run.stateSnapshot.diceHistory?.first?.total, 11)
        XCTAssertTrue(run.battle?.log.first?.contains("骰子 · 古兹") == true)

        store.clearDiceHistory(in: run)
        XCTAssertTrue(store.diceHistory(in: run).isEmpty)
    }
}
