import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct DicePanel: View {
    @Bindable var run: RunRecord
    @AppStorage("dicePanel.expanded") private var isExpanded = true
    @State private var subject = ""

    var body: some View {
        Group {
            if isExpanded { expandedPanel } else { collapsedButton }
        }
    }

    private var collapsedButton: some View {
        Button {
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
    }

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "die.face.5").foregroundStyle(Theme.red)
                Text("骰子").bookUI(13, weight: .semibold)
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
            DiceWorkspace(run: run, subject: $subject)
        }
        .background(Theme.card)
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Theme.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 7)
        .accessibilityIdentifier("dice-panel")
    }
}

struct DiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var run: RunRecord
    @State private var subject: String
    let logToBattle: Bool

    init(run: RunRecord, subject: String, logToBattle: Bool = false) {
        self.run = run
        self.logToBattle = logToBattle
        _subject = State(initialValue: subject)
    }

    var body: some View {
        BookFormSheet(
            title: "投掷",
            primaryTitle: "完成",
            onCancel: { dismiss() },
            onPrimary: { dismiss() }
        ) {
            DiceWorkspace(run: run, subject: $subject, logToBattle: logToBattle)
        }
    }
}
