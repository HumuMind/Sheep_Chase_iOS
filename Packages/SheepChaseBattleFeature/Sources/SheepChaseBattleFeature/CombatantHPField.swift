import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct CombatantHPField: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    let combatantID: UUID

    @State private var draft = ""
    @FocusState private var focused: Bool

    private var combatant: BattleCombatant? {
        run.battle?.combatants.first { $0.id == combatantID }
    }

    var body: some View {
        TextField("0", text: $draft)
            .textFieldStyle(.roundedBorder)
            .bookUI(13, monospaced: true)
            .frame(width: 54)
            .selectAllOnFocus()
            .focused($focused)
            .onSubmit { commit() }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { commit() }
            }
            .onChange(of: combatant?.hp) { _, newValue in
                guard !focused else { return }
                draft = String(newValue ?? 0)
            }
            .onAppear { syncDraft() }
            .help("输入后按回车保存")
    }

    private func syncDraft() {
        draft = String(combatant?.hp ?? 0)
    }

    private func commit() {
        guard let combatant else {
            syncDraft()
            return
        }
        guard let entered = Int(draft.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            syncDraft()
            return
        }
        if entered != combatant.hp {
            store.setHP(entered, forID: combatantID, in: run)
        }
        draft = String(min(max(0, entered), combatant.maxHP))
    }
}
