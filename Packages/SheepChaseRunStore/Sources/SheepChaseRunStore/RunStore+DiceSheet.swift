import Foundation

public struct DiceSheetRequest: Identifiable, Hashable {
    public let id = UUID()
    public let subject: String
    public let logToBattle: Bool

    public init(subject: String, logToBattle: Bool = false) {
        self.subject = subject
        self.logToBattle = logToBattle
    }
}

@MainActor
extension RunStore {
    public func openDiceSheet(subject: String, logToBattle: Bool = false) {
        diceSheetRequest = DiceSheetRequest(subject: subject, logToBattle: logToBattle)
    }

    public func closeDiceSheet() {
        diceSheetRequest = nil
    }
}
