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
        BookFormSheet(
            title: "调整遭遇",
            primaryTitle: "保存",
            onCancel: { dismiss() },
            onPrimary: save
        ) {
            BookFormSection("怪物数量") {
                ForEach(monsters) { monster in
                    Stepper(value: Binding(
                        get: { counts[monster.id] ?? 0 },
                        set: { counts[monster.id] = max(0, $0) }
                    ), in: 0...20) {
                        HStack {
                            Text(monster.name)
                                .font(Theme.serif(14))
                            Spacer()
                            Text("× \(counts[monster.id] ?? 0)")
                                .font(Theme.serif(12).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            BookFormSection("调整备注") {
                BookTextEditor("为什么改、这组怪怎么打……", text: $note, minHeight: 80)
            }
            Text("保存后“按调整筹备”会把这组怪物加入战斗筹备；清空全部数量并保存可恢复原始组合。")
                .font(Theme.serif(11))
                .foregroundStyle(.secondary)
        }
        .onAppear {
            if let adjustment = store.encounterAdjustment(for: encounter.id, in: run) {
                counts = Dictionary(uniqueKeysWithValues: adjustment.combatants.map { ($0.monsterID, $0.count) })
                note = adjustment.note
            } else {
                counts = Dictionary(uniqueKeysWithValues: encounter.combatants.map { ($0.monsterId, $0.count) })
            }
        }
    }

    private func save() {
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
