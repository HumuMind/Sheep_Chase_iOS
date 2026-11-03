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
        subject: String? = nil,
        logToBattle: Bool = false,
        in run: RunRecord,
        die: (Int) -> Int = { sides in Int.random(in: 1...sides) }
    ) -> DiceRoll {
        var result = DiceRoller.roll(expression, command: command, die: die)
        let trimmedSubject = subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        result.subject = trimmedSubject?.isEmpty == true ? nil : trimmedSubject
        var history = run.diceHistory
        history.insert(result, at: 0)
        if history.count > 30 { history = Array(history.prefix(30)) }
        run.diceHistory = history
        if logToBattle, var battle = run.battle {
            let subjectPrefix = result.subject.map { "\($0) · " } ?? ""
            battle.log.insert("骰子 · \(subjectPrefix)\(result.command) = \(result.total)", at: 0)
            run.battle = battle
        }
        commit(run)
        return result
    }

    public func clearDiceHistory(in run: RunRecord) {
        run.diceHistory = []
        commit(run)
    }
}
