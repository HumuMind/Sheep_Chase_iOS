import Foundation
import SwiftUI

public extension Notification.Name {
    static let toggleQuickReferencePanel = Notification.Name("SheepChase.toggleQuickReferencePanel")
    static let toggleDicePanel = Notification.Name("SheepChase.toggleDicePanel")
}

public struct RunShortcutCommands: Commands {
    public init() {}

    public var body: some Commands {
        CommandMenu("桌面工具") {
            Button("打开或收起速查面板") {
                NotificationCenter.default.post(name: .toggleQuickReferencePanel, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("打开或收起骰子面板") {
                NotificationCenter.default.post(name: .toggleDicePanel, object: nil)
            }
            .keyboardShortcut("d", modifiers: .command)
        }
    }
}
