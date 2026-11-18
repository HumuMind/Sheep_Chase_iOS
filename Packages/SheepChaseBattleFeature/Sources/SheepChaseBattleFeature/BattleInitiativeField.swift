import SheepChaseUI
import SwiftUI

struct BattleInitiativeField: View {
    let name: String
    let value: Int
    let isActive: Bool
    let onCommit: (Int) -> Void

    @State private var text: String
    @State private var lastCommitted: Int
    @State private var isHovering = false
    @FocusState private var isFocused: Bool

    init(name: String, value: Int, isActive: Bool, onCommit: @escaping (Int) -> Void) {
        self.name = name
        self.value = value
        self.isActive = isActive
        self.onCommit = onCommit
        _text = State(initialValue: String(value))
        _lastCommitted = State(initialValue: value)
    }

    var body: some View {
        TextField("先攻", text: $text)
            .textFieldStyle(.plain)
            .bookUI(11, weight: .semibold, monospaced: true)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(isActive ? Theme.red : Theme.inkSoft)
            .frame(width: 28)
            .padding(.vertical, 2)
            .background(
                (isActive ? Theme.red : Theme.inkSoft).opacity(isFocused ? 0.14 : 0.06),
                in: RoundedRectangle(cornerRadius: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        (isActive ? Theme.red : Theme.inkSoft)
                            .opacity(isFocused ? 0.55 : (isHovering ? 0.32 : 0.18)),
                        lineWidth: 1
                    )
            )
            .focused($isFocused)
            .onHover { isHovering = $0 }
            .onSubmit(commit)
            .onChange(of: isFocused) { _, focused in
                if !focused { commit() }
            }
            .onChange(of: value) { _, newValue in
                lastCommitted = newValue
                if !isFocused { text = String(newValue) }
            }
            .accessibilityLabel("\(name)先攻")
            .help("修改\(name)先攻，回车或离开输入框后生效")
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Int(trimmed), parsed != lastCommitted else {
            text = String(lastCommitted)
            return
        }
        lastCommitted = parsed
        text = String(parsed)
        onCommit(parsed)
    }
}
