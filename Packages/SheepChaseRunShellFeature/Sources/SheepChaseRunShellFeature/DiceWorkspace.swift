import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct DiceWorkspace: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @Binding var subject: String

    @AppStorage("dicePanel.quickExpanded") private var quickExpanded = false
    @State private var diceCounts: [Int: Int] = [:]
    @State private var modifier = 0
    @State private var mode: DiceMode = .normal
    @State private var command = ""
    @State private var errorMessage: String?
    @State private var showHelp = false

    private let dice = [4, 6, 8, 10, 12, 20, 100]
    private var history: [DiceRoll] { store.diceHistory(in: run) }

    private var terms: [DiceTerm] {
        dice.compactMap { sides in
            guard let count = diceCounts[sides], count > 0 else { return nil }
            return DiceTerm(count: count, sides: sides)
        }
    }

    private var formula: String {
        guard !terms.isEmpty else { return "选择骰子" }
        let dicePart = terms.map { "\($0.count)d\($0.sides)" }.joined(separator: "+")
        return "\(mode == .normal ? "" : mode.title + " ")\(dicePart)\(signed(modifier))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            historyColumn.frame(width: 205)
            Divider()
            ScrollView {
                rightColumn.padding(11)
            }
            .frame(width: 350)
        }
        .frame(width: 556, height: 500)
        .sheet(isPresented: $showHelp) {
            DiceHelpSheet { example in
                command = example
                errorMessage = nil
            }
        }
    }

    private var historyColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("记录").bookUI(13, weight: .semibold)
                Spacer()
                if !history.isEmpty {
                    Button("清空") { store.clearDiceHistory(in: run) }
                        .buttonStyle(.borderless)
                        .bookUI(9)
                        .foregroundStyle(.secondary)
                }
            }
            if history.isEmpty {
                Text("还没有投掷记录。")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(history) { roll in
                            VStack(alignment: .leading, spacing: 2) {
                                if let subject = roll.subject {
                                    Text(subject)
                                        .bookUI(9, weight: .semibold)
                                        .foregroundStyle(Theme.gold)
                                }
                                HStack(alignment: .firstTextBaseline) {
                                    Text(roll.command)
                                        .bookUI(10, weight: .medium)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 2)
                                    Text("\(roll.total)")
                                        .bookUI(16, weight: .bold, monospaced: true)
                                        .foregroundStyle(Theme.red)
                                }
                                Text(roll.detail)
                                    .bookUI(9)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 5)
                            .background(Theme.readingPaper, in: RoundedRectangle(cornerRadius: 5))
                        }
                    }
                }
            }
        }
        .padding(10)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Theme.readingPaper.opacity(0.55))
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 9) {
            subjectRow
            commandRow
            if let errorMessage {
                Text(errorMessage).bookUI(10).foregroundStyle(Theme.red)
            }
            if let latest = history.first { latestCard(latest) }
            quickSection
        }
    }

    private var subjectRow: some View {
        HStack(spacing: 5) {
            Text("投掷者")
                .bookUI(10, weight: .semibold)
                .foregroundStyle(.secondary)
            TextField("未指定", text: $subject)
                .textFieldStyle(.roundedBorder)
                .bookUI(11)
                .selectAllOnFocus()
            Button { showHelp = true } label: {
                Image(systemName: "questionmark.circle").bookUI(13)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("骰子指令帮助")
            .accessibilityIdentifier("dice-help")
        }
    }

    private var commandRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("指令")
                .bookUI(10, weight: .semibold)
                .foregroundStyle(.secondary)
            HStack(spacing: 5) {
                TextField("例如 1d20+5 或 优势 2d20+3", text: $command)
                    .textFieldStyle(.roundedBorder)
                    .bookUI(11)
                    .selectAllOnFocus()
                    .onSubmit { rollCommand() }
                Button { rollCommand() } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .bookUI(16)
                        .foregroundStyle(Theme.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("投掷指令")
            }
            Text("支持 1d20+5、2d6+3、优势 2d20；点 ? 查看帮助")
                .bookUI(9)
                .foregroundStyle(.secondary)
        }
    }

    private func latestCard(_ roll: DiceRoll) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("最近").bookUI(10, weight: .semibold).foregroundStyle(Theme.gold)
                Spacer()
                Text("\(roll.total)").bookUI(20, weight: .bold, monospaced: true).foregroundStyle(Theme.red)
            }
            if let subject = roll.subject {
                Text(subject).bookUI(10, weight: .medium).foregroundStyle(Theme.gold)
            }
            Text(roll.command)
                .bookUI(11, weight: .medium, monospaced: true)
                .foregroundStyle(Theme.ink)
            Text(roll.detail)
                .bookUI(10)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(Theme.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Theme.gold.opacity(0.30), lineWidth: 1)
        )
    }

    private var quickSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button {
                withAnimation(.easeInOut(duration: 0.16)) { quickExpanded.toggle() }
            } label: {
                HStack {
                    Label("手动投掷", systemImage: "hand.tap")
                        .bookUI(11, weight: .semibold)
                    Spacer()
                    Image(systemName: quickExpanded ? "chevron.up" : "chevron.down")
                        .bookUI(10)
                }
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if quickExpanded {
                VStack(alignment: .leading, spacing: 7) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                        ForEach(dice, id: \.self) { value in
                            Button { addDie(value) } label: {
                                VStack(spacing: 2) {
                                    Text("d\(value)")
                                        .bookUI(14, weight: .semibold, monospaced: true)
                                    if let count = diceCounts[value], count > 0 {
                                        Text("×\(count)").bookUI(10, weight: .medium).foregroundStyle(Theme.red)
                                    } else {
                                        Text("添加").bookUI(9).foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(
                                    (diceCounts[value] ?? 0) > 0 ? Theme.red.opacity(0.08) : Theme.paperDeep.opacity(0.25),
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke((diceCounts[value] ?? 0) > 0 ? Theme.red.opacity(0.35) : Theme.line.opacity(0.55), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Theme.ink)
                        }
                    }

                    if !terms.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(terms, id: \.sides) { term in
                                HStack(spacing: 3) {
                                    Text("\(term.count)d\(term.sides)")
                                        .bookUI(10, weight: .medium, monospaced: true)
                                    Button { removeDie(term.sides) } label: {
                                        Image(systemName: "minus.circle.fill").bookUI(9)
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Theme.red)
                                }
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.readingPaper, in: Capsule())
                                .overlay(Capsule().stroke(Theme.line.opacity(0.6), lineWidth: 1))
                            }
                            Spacer()
                            Button("清空") { diceCounts = [:] }
                                .buttonStyle(.borderless)
                                .bookUI(9)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 5) {
                        Text("加值").bookUI(10).foregroundStyle(.secondary)
                        Text(signed(modifier))
                            .bookUI(12, weight: .semibold, monospaced: true)
                            .foregroundStyle(modifier == 0 ? Theme.ink : Theme.red)
                        Spacer()
                        Button("归零") { modifier = 0 }
                            .buttonStyle(.borderless)
                            .bookUI(9)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 4) {
                        ForEach([1, 2, 3, 5, -1, -2, -5], id: \.self) { value in
                            Button(value > 0 ? "+\(value)" : "\(value)") {
                                modifier += value
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .tint(value > 0 ? Theme.green : Theme.inkSoft)
                        }
                    }

                    Picker("模式", selection: $mode) {
                        ForEach(DiceMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: mode) { _, _ in errorMessage = nil }

                    Button { rollQuick() } label: {
                        Label("投掷 \(formula)", systemImage: "die.face.5")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                    .disabled(terms.isEmpty)
                }
            }
        }
    }

    private func rollQuick() {
        guard !terms.isEmpty else {
            errorMessage = "先点几个骰子。"
            return
        }
        if mode != .normal, terms.contains(where: { $0.sides != 20 }) {
            errorMessage = "优势/劣势只适用于纯 d20；请移除其他骰子。"
            return
        }
        _ = store.rollDice(
            DiceExpression(terms: terms, modifier: modifier, mode: mode),
            command: formula,
            subject: subject,
            in: run
        )
        errorMessage = nil
    }

    private func rollCommand() {
        switch DiceParser.parse(command) {
        case .success(let expression):
            _ = store.rollDice(
                expression,
                command: command.trimmingCharacters(in: .whitespacesAndNewlines),
                subject: subject,
                in: run
            )
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func addDie(_ sides: Int) {
        diceCounts[sides, default: 0] += 1
        errorMessage = nil
    }

    private func removeDie(_ sides: Int) {
        guard let count = diceCounts[sides], count > 0 else { return }
        diceCounts[sides] = count > 1 ? count - 1 : nil
        errorMessage = nil
    }

    private func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
