import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func customMonsters(in run: RunRecord) -> [RunCustomMonster] {
        run.customMonsters.sorted { $0.createdAt < $1.createdAt }
    }

    public func addCustomMonster(
        name: String,
        size: String,
        type: String,
        alignment: String,
        ac: Int,
        hp: Int,
        initiativeModifier: Int,
        actionText: String,
        in run: RunRecord
    ) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let actionText = actionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !actionText.isEmpty else { return }
        run.customMonsters.append(
            RunCustomMonster(
                name: name,
                size: size.isEmpty ? "中型" : size,
                type: type.isEmpty ? "怪兽" : type,
                alignment: alignment.isEmpty ? "无阵营" : alignment,
                ac: max(1, ac),
                hp: max(1, hp),
                initiativeModifier: initiativeModifier,
                actionText: actionText
            )
        )
        commit(run)
    }

    public func deleteCustomMonster(_ id: UUID, in run: RunRecord) {
        let targetID = "custom-monster-\(id.uuidString)"
        run.customMonsters.removeAll { $0.id == id }
        run.pinnedReferenceIDs.removeAll { $0 == "monster:\(targetID)" }
        run.annotations.removeAll { $0.targetKind == .monster && $0.targetID == targetID }
        commit(run)
    }

    public func monster(id: String, in run: RunRecord) -> ContentPack.Monster? {
        if let monster = content.monsters.first(where: { $0.id == id }) {
            return monster
        }
        guard let custom = run.customMonsters.first(where: { "custom-monster-\($0.id.uuidString)" == id }) else { return nil }
        return customMonsterModel(custom)
    }

    public func orderedBattleMonsters(in run: RunRecord) -> [ContentPack.Monster] {
        content.monsters + customMonsters(in: run).map(customMonsterModel)
    }

    public func battleMonsters(in run: RunRecord) -> [ContentPack.Monster] {
        orderedBattleMonsters(in: run)
    }

    private func customMonsterModel(_ custom: RunCustomMonster) -> ContentPack.Monster {
        ContentPack.Monster.custom(
            id: "custom-monster-\(custom.id.uuidString)",
            name: custom.name,
            size: custom.size,
            type: custom.type,
            alignment: custom.alignment,
            ac: ContentPack.ArmorClass(value: custom.ac),
            hp: ContentPack.HitPoints(average: custom.hp, formula: "\(custom.hp)"),
            speed: ContentPack.Speed(),
            abilities: ContentPack.Abilities(
                str: 10,
                dex: 10 + custom.initiativeModifier * 2,
                con: 10,
                int: 10,
                wis: 10,
                cha: 10
            ),
            senses: ContentPack.Senses(passivePerception: 10),
            challenge: ContentPack.Challenge(rating: 0, xp: 0),
            actions: [ContentPack.TextPair(name: "攻击", text: custom.actionText)],
            sourceRef: "自定义怪物"
        )
    }
}
