import SheepChaseBattleEngine
import SheepChasePersistence
import SheepChaseCore
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct CombatantInfoSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord
    let combatant: BattleCombatant
    let monster: ContentPack.Monster?
    let member: PartyMember?

    @State private var selectedRule: ContentPack.RuleCard?
    @State private var selectedSpell: ContentPack.SpellCard?

    var body: some View {
        BookFormSheet(
            title: "对象信息 · \(combatant.name)",
            primaryTitle: "完成",
            onCancel: { dismiss() },
            onPrimary: { dismiss() }
        ) {
            CombatantInfoView(
                combatant: combatant,
                monster: monster,
                member: member,
                onOpenRule: { ruleID in
                    if let rule = store.rule(id: ruleID) { selectedRule = rule }
                },
                onOpenSpell: { spellID in
                    if let spell = store.spell(id: spellID) { selectedSpell = spell }
                }
            )
        }
        .sheet(item: $selectedRule) { rule in
            RuleSheetView(
                rule: rule,
                annotations: store.annotations(kind: .rule, targetID: rule.id, in: run),
                onAnnotationChange: { updated in
                    store.replaceAnnotations(kind: .rule, targetID: rule.id, with: updated, in: run)
                }
            )
            .environment(store)
        }
        .sheet(item: $selectedSpell) { spell in
            SpellSheetView(
                spell: spell,
                annotations: store.annotations(kind: .spell, targetID: spell.id, in: run),
                onAnnotationChange: { updated in
                    store.replaceAnnotations(kind: .spell, targetID: spell.id, with: updated, in: run)
                }
            )
            .environment(store)
        }
    }
}
