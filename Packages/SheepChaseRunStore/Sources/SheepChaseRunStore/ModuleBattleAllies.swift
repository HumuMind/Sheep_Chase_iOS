import SheepChaseCore

/// 模组自带的 NPC 盟友数据。
///
/// 范席尔被变成绵羊后的数据在模组正文里，内容包没有对应的怪物条目，
/// 因此在这里集中维护，方便核对与后续修改。
enum ModuleBattleAllies {
    static let finethirSheepID = "finethir-sheep"

    static func finethirSheep() -> BattleAlly {
        BattleAlly(
            baseID: finethirSheepID,
            name: "范席尔（绵羊）",
            subtitle: "被变成绵羊的法师 · NPC 盟友",
            ac: 10,
            hp: 3,
            maxHP: 3,
            initiativeModifier: 0,
            speed: 40,
            strength: 12,
            dexterity: 10,
            constitution: 11,
            intelligence: 17,
            wisdom: 12,
            charisma: 5,
            skills: ["感知 +2"],
            passivePerception: 12,
            languages: [],
            actions: ["顶撞。近战武器攻击：命中 +3，触及 5 尺，单一目标。命中：3（1d4+1）钝击伤害。"]
        )
    }
}
