import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func diceHistory(in run: RunRecord) -> [DiceRoll] {
        run.diceHistory
    }

    @discardableResult
    public func rollDice(
        _ expression: DiceExpression,
        command: String,
        in run: RunRecord,
        die: (Int) -> Int = { sides in Int.random(in: 1...sides) }
    ) -> DiceRoll {
        let result = DiceRoller.roll(expression, command: command, die: die)
        var history = run.diceHistory
        history.insert(result, at: 0)
        if history.count > 30 { history = Array(history.prefix(30)) }
        run.diceHistory = history
        commit(run)
        return result
    }

    public func clearDiceHistory(in run: RunRecord) {
        run.diceHistory = []
        commit(run)
    }
}
