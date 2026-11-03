import Foundation

public struct DiceSheetRequest: Identifiable, Hashable {
    public let id = UUID()
    public let subject: String

    public init(subject: String) {
        self.subject = subject
    }
}

@MainActor
extension RunStore {
    public func openDiceSheet(subject: String) {
        diceSheetRequest = DiceSheetRequest(subject: subject)
    }

    public func closeDiceSheet() {
        diceSheetRequest = nil
    }
}
