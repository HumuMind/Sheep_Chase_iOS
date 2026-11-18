import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct DicePanel: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @AppStorage("dicePanel.expanded") private var isExpanded = true
    @State private var subject = ""
    @State private var logToBattle = false

    var body: some View {
        Group {
            if isExpanded { expandedPanel } else { collapsedButton }
        }
        .task(id: store.dicePanelRequest) {
            guard let request = store.dicePanelRequest else { return }
            subject = request.subject
            logToBattle = request.logToBattle
            withAnimation(.easeInOut(duration: 0.16)) { isExpanded = true }
            store.dicePanelRequest = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleDicePanel)) { _ in
            if !isExpanded {
                subject = ""
                logToBattle = false
            }
            withAnimation(.easeInOut(duration: 0.16)) { isExpanded.toggle() }
        }
    }

    private var collapsedButton: some View {
        Button {
            subject = ""
            logToBattle = false
            withAnimation(.easeInOut(duration: 0.16)) { isExpanded = true }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "die.face.5")
                Text("骰子")
                if let latest = run.diceHistory.first {
                    Text("\(latest.total)")
                        .bookUI(10, monospaced: true)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Theme.red.opacity(0.1), in: Capsule())
                }
            }
            .bookUI(13, weight: .medium)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.card)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dice-panel-open")
        .help("骰子面板（⌘D）")
    }

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "die.face.5").foregroundStyle(Theme.red)
                Text("骰子")
                    .bookUI(13, weight: .semibold)
                    .help("骰子面板（⌘D）")
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { isExpanded = false }
                } label: {
                    Label("收起", systemImage: "chevron.down")
                        .bookUI(10, weight: .medium)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("dice-panel-close")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            Divider().opacity(0.5)
            DiceWorkspace(run: run, subject: $subject, logToBattle: logToBattle)
        }
        .frame(width: 480)
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 7)
        .accessibilityIdentifier("dice-panel")
    }
}
