import Foundation

public struct DicePanelRequest: Identifiable, Hashable {
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
    public func openDicePanel(subject: String, logToBattle: Bool = false) {
        dicePanelRequest = DicePanelRequest(subject: subject, logToBattle: logToBattle)
    }

    public func closeDicePanel() {
        dicePanelRequest = nil
    }
}
