import SwiftUI
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI

struct EncounterAdjustmentSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let encounter: ContentPack.Encounter
    let run: RunRecord

    @State private var counts: [String: Int] = [:]
    @State private var note = ""

    private var monsters: [ContentPack.Monster] {
        store.orderedBattleMonsters(in: run)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("怪物数量") {
                    ForEach(monsters) { monster in
                        Stepper(value: Binding(
                            get: { counts[monster.id] ?? 0 },
                            set: { counts[monster.id] = max(0, $0) }
                        ), in: 0...20) {
                            HStack {
                                Text(monster.name)
                                Spacer()
                                Text("× \(counts[monster.id] ?? 0)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("调整备注") {
                    TextEditor(text: $note)
                        .frame(minHeight: 80)
                }
                Section {
                    Text("保存后“按调整筹备”会把这组怪物加入战斗筹备。清空全部数量并保存可恢复原始组合。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("调整遭遇 · \(encounter.title)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.setEncounterAdjustment(
                            encounterID: encounter.id,
                            combatants: counts.compactMap { monsterID, count in
                                count > 0 ? RunEncounterCombatant(monsterID: monsterID, count: count) : nil
                            },
                            note: note,
                            in: run
                        )
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 500)
        .onAppear {
            if let adjustment = store.encounterAdjustment(for: encounter.id, in: run) {
                counts = Dictionary(uniqueKeysWithValues: adjustment.combatants.map { ($0.monsterID, $0.count) })
                note = adjustment.note
            } else {
                counts = Dictionary(uniqueKeysWithValues: encounter.combatants.map { ($0.monsterId, $0.count) })
            }
        }
    }
}
