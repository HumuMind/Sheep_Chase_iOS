import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct DicePanel: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    @AppStorage("dicePanel.expanded") private var isExpanded = true
    @State private var count = 1
    @State private var sides = 20
    @State private var modifier = 0
    @State private var mode: DiceMode = .normal
    @State private var command = ""
    @State private var errorMessage: String?
    @State private var showHelp = false

    private let dice = [4, 6, 8, 10, 12, 20, 100]

    private var history: [DiceRoll] { store.diceHistory(in: run) }

    private var formula: String {
        "\(mode == .normal ? "" : mode.title + " ")\(count)d\(sides)\(signed(modifier))"
    }

    var body: some View {
        Group {
            if isExpanded {
                expandedPanel
            } else {
                collapsedButton
            }
        }
        .sheet(isPresented: $showHelp) {
            DiceHelpSheet { example in
                command = example
                errorMessage = nil
            }
        }
    }

    private var collapsedButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { isExpanded = true }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "die.face.5")
                Text("骰子")
                if let latest = history.first {
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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.16), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("dice-panel-open")
    }

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "die.face.5")
                    .foregroundStyle(Theme.red)
                Text("骰子")
                    .bookUI(13, weight: .semibold)
                Spacer()
                Button {
                    showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .bookUI(12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("骰子指令帮助")
                .accessibilityIdentifier("dice-help")
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { isExpanded = false }
                } label: {
                    Image(systemName: "chevron.down")
                        .bookUI(11)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("dice-panel-close")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            Divider().opacity(0.5)

            ScrollView {
                VStack(alignment: .leading, spacing: 9) {
                    if let latest = history.first {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("最近")
                                .bookUI(9, weight: .semibold)
                                .foregroundStyle(.secondary)
                            Text("\(latest.command) = \(latest.total)")
                                .bookUI(12, weight: .medium, monospaced: true)
                                .foregroundStyle(Theme.ink)
                            if latest.mode != .normal {
                                Text(latest.detail)
                                    .bookUI(10)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        }
                        .padding(.bottom, 2)
                    }

                    HStack(spacing: 4) {
                        ForEach(dice, id: \.self) { value in
                            Button("d\(value)") {
                                sides = value
                                if value != 20, mode != .normal { mode = .normal }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .tint(sides == value ? Theme.red : Theme.inkSoft)
                        }
                    }

                    HStack(spacing: 8) {
                        Stepper("数量 \(count)", value: $count, in: 1...20)
                            .bookUI(11)
                        Stepper("加值 \(signed(modifier))", value: $modifier, in: -20...20)
                            .bookUI(11)
                    }

                    Picker("模式", selection: $mode) {
                        ForEach(DiceMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: mode) { _, newMode in
                        if newMode != .normal { sides = 20 }
                    }

                    Button {
                        rollQuick()
                    } label: {
                        Label("投掷 \(formula)", systemImage: "die.face.5")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)

                    if let errorMessage {
                        Text(errorMessage)
                            .bookUI(10)
                            .foregroundStyle(Theme.red)
                    }

                    Divider().opacity(0.4)

                    HStack(spacing: 5) {
                        TextField("或输入 /r 1d20+5", text: $command)
                            .textFieldStyle(.roundedBorder)
                            .bookUI(11)
                            .selectAllOnFocus()
                            .onSubmit { rollCommand() }
                        Button {
                            rollCommand()
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .bookUI(16)
                                .foregroundStyle(Theme.red)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("投掷指令")
                    }

                    if !history.isEmpty {
                        HStack {
                            Text("\(history.count) 条记录")
                                .bookUI(9)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("清空") {
                                store.clearDiceHistory(in: run)
                            }
                            .buttonStyle(.borderless)
                            .bookUI(10)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
            }
            .frame(maxHeight: 410)
        }
        .frame(width: 330)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Theme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.18), radius: 16, y: 7)
        .accessibilityIdentifier("dice-panel")
    }

    private func rollQuick() {
        if mode != .normal, sides != 20 {
            errorMessage = "优势/劣势只适用于 d20。"
            return
        }
        let expression = DiceExpression(
            terms: [DiceTerm(count: count, sides: sides)],
            modifier: modifier,
            mode: mode
        )
        let result = store.rollDice(expression, command: formula, in: run)
        errorMessage = nil
        _ = result
    }

    private func rollCommand() {
        switch DiceParser.parse(command) {
        case .success(let expression):
            _ = store.rollDice(expression, command: command.trimmingCharacters(in: .whitespacesAndNewlines), in: run)
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
