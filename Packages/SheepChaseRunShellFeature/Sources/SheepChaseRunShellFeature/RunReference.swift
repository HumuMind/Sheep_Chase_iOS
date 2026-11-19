import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

/// 可在任意视图里打开的资料类型，用来把 6 个内容 Sheet 收敛成一次路由。
enum RunReference: Identifiable {
    case npc(ContentPack.NPC)
    case handout(ContentPack.Handout)
    case item(ContentPack.Item)
    case rule(ContentPack.RuleCard)
    case spell(ContentPack.SpellCard)
    case monster(ContentPack.Monster)

    var id: String {
        switch self {
        case .npc(let npc): "npc-\(npc.id)"
        case .handout(let handout): "handout-\(handout.id)"
        case .item(let item): "item-\(item.id)"
        case .rule(let rule): "rule-\(rule.id)"
        case .spell(let spell): "spell-\(spell.id)"
        case .monster(let monster): "monster-\(monster.id)"
        }
    }

    var annotationKind: DMAnnotationTargetKind {
        switch self {
        case .npc: .npc
        case .handout: .handout
        case .item: .item
        case .rule: .rule
        case .spell: .spell
        case .monster: .monster
        }
    }

    var annotationTargetID: String {
        switch self {
        case .npc(let npc): npc.id
        case .handout(let handout): handout.id
        case .item(let item): item.id
        case .rule(let rule): rule.id
        case .spell(let spell): spell.id
        case .monster(let monster): monster.id
        }
    }
}

/// 把选中的资料渲染成对应 Sheet，并统一接好批注与怪物改动回调。
struct RunReferenceSheet: View {
    @Environment(RunStore.self) private var store
    let reference: RunReference
    let run: RunRecord

    var body: some View {
        switch reference {
        case .npc(let npc):
            NPCSheetView(
                npc: npc,
                annotations: annotations,
                onAnnotationChange: { replaceAnnotations(with: $0) }
            )
        case .handout(let handout):
            HandoutSheetView(
                handout: handout,
                asset: handout.imageAssetId.flatMap { store.asset(id: $0) },
                annotations: annotations,
                onAnnotationChange: { replaceAnnotations(with: $0) }
            )
        case .item(let item):
            ItemSheetView(
                item: item,
                annotations: annotations,
                onAnnotationChange: { replaceAnnotations(with: $0) }
            )
        case .rule(let rule):
            RuleSheetView(
                rule: rule,
                annotations: annotations,
                onAnnotationChange: { replaceAnnotations(with: $0) }
            )
        case .spell(let spell):
            SpellSheetView(
                spell: spell,
                annotations: annotations,
                onAnnotationChange: { replaceAnnotations(with: $0) }
            )
        case .monster(let monster):
            MonsterSheetView(
                monster: monster,
                annotations: annotations,
                onAnnotationChange: { replaceAnnotations(with: $0) },
                override: store.monsterOverride(for: monster.id, in: run),
                onOverrideSave: { ac, hp, initMod, note in
                    store.setMonsterOverride(
                        monsterID: monster.id,
                        ac: ac,
                        hp: hp,
                        initiativeModifier: initMod,
                        note: note,
                        in: run
                    )
                },
                onOverrideClear: {
                    store.clearMonsterOverride(monsterID: monster.id, in: run)
                }
            )
        }
    }

    private var annotations: [DMAnnotation] {
        store.annotations(kind: reference.annotationKind, targetID: reference.annotationTargetID, in: run)
    }

    private func replaceAnnotations(with updated: [DMAnnotation]) {
        store.replaceAnnotations(
            kind: reference.annotationKind,
            targetID: reference.annotationTargetID,
            with: updated,
            in: run
        )
    }
}
