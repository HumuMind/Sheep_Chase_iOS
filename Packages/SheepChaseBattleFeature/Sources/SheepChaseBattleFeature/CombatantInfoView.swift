import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseCore
import SheepChaseUI
import SwiftUI

struct CombatantInfoView: View {
    @Environment(RunStore.self) private var store
    let combatant: BattleCombatant
    let monster: ContentPack.Monster?
    let member: PartyMember?
    let ally: BattleAlly?
    let onOpenRule: (String) -> Void
    let onOpenSpell: (String) -> Void

    var body: some View {
        GroupBox("当前对象信息") {
            VStack(alignment: .leading, spacing: 8) {
                header
                if let monster {
                    monsterInfo(monster)
                } else if let member {
                    playerInfo(member)
                } else if let ally {
                    allyInfo(ally)
                } else {
                    Text("找不到这个对象的详细资料。")
                        .bookUI(12)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 3)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(combatant.name)
                .bookSerif(20, weight: .semibold)
            Text(combatant.kind == .player ? "玩家" : (combatant.kind == .npc ? "NPC" : "怪物"))
                .bookUI(10)
                .foregroundStyle(.secondary)
            Spacer()
            Text("AC \(combatant.ac) · HP \(combatant.hp)/\(combatant.maxHP)")
                .bookUI(11, monospaced: true)
                .foregroundStyle(.secondary)
        }
    }

    private func monsterInfo(_ monster: ContentPack.Monster) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(monster.size)\(monster.type) · \(monster.alignment)")
                .bookUI(12)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                info("速度", "\(monster.speed.walk) 尺")
                info("先攻", signed(combatant.initiative))
                if let temp = combatant.tempHP, temp > 0 {
                    info("临时 HP", "\(temp)")
                }
                info("挑战等级", "\(monster.challenge.rating.formatted())（\(monster.challenge.xp) XP）")
            }

            HStack(spacing: 8) {
                ability("力量", monster.abilities.str)
                ability("敏捷", monster.abilities.dex)
                ability("体质", monster.abilities.con)
                ability("智力", monster.abilities.int)
                ability("感知", monster.abilities.wis)
                ability("魅力", monster.abilities.cha)
            }

            if let skills = monster.skills, !skills.isEmpty {
                Text("技能：\(skills.joined(separator: "、"))").bookUI(11).foregroundStyle(.secondary)
            }
            if let senses = monster.senses {
                Text("感官：被动感知 \(senses.passivePerception)").bookUI(11).foregroundStyle(.secondary)
            }
            if let languages = monster.languages, !languages.isEmpty {
                Text("语言：\(languages.joined(separator: "、"))").bookUI(11).foregroundStyle(.secondary)
            }

            if !combatant.conditions.isEmpty {
                Text("状态：\(combatant.conditions.joined(separator: "、"))")
                    .bookUI(11)
                    .foregroundStyle(Theme.red)
            }
            if let concentration = combatant.concentration, !concentration.isEmpty {
                Text("专注：\(concentration)").bookUI(11).foregroundStyle(Theme.red)
            }

            ForEach((monster.traits ?? []) + monster.actions) { pair in
                Text("**\(pair.name)。** \(pair.text)")
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
            }

            HStack(spacing: 8) {
                ForEach(monster.ruleIds ?? [], id: \.self) { ruleID in
                    if let rule = store.rule(id: ruleID) {
                        Button(rule.term) { onOpenRule(ruleID) }
                            .buttonStyle(.borderless)
                            .bookUI(11)
                            .foregroundStyle(Theme.red)
                    }
                }
                ForEach(monster.spellIds ?? [], id: \.self) { spellID in
                    if let spell = store.spell(id: spellID) {
                        Button(spell.name) { onOpenSpell(spellID) }
                            .buttonStyle(.borderless)
                            .bookUI(11)
                            .foregroundStyle(Theme.red)
                    }
                }
            }
        }
    }

    private func allyInfo(_ ally: BattleAlly) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(ally.subtitle.isEmpty ? "NPC 盟友" : ally.subtitle)
                .bookUI(12)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                info("速度", "\(ally.speed) 尺")
                info("先攻", signed(combatant.initiative))
                info("临时 HP", "\(combatant.tempHP ?? 0)")
                info("被动感知", "\(ally.passivePerception)")
            }
            HStack(spacing: 8) {
                ability("力量", ally.strength)
                ability("敏捷", ally.dexterity)
                ability("体质", ally.constitution)
                ability("智力", ally.intelligence)
                ability("感知", ally.wisdom)
                ability("魅力", ally.charisma)
            }
            if !ally.skills.isEmpty {
                Text("技能：\(ally.skills.joined(separator: "、"))")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }
            if !ally.languages.isEmpty {
                Text("语言：\(ally.languages.joined(separator: "、"))")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }
            if !combatant.conditions.isEmpty {
                Text("状态：\(combatant.conditions.joined(separator: "、"))")
                    .bookUI(11)
                    .foregroundStyle(Theme.red)
            }
            if let concentration = combatant.concentration, !concentration.isEmpty {
                Text("专注：\(concentration)").bookUI(11).foregroundStyle(Theme.red)
            }
            ForEach(ally.actions, id: \.self) { action in
                Text(action)
                    .bookUI(12)
                    .foregroundStyle(Theme.inkSoft)
            }
            Text("NPC 盟友的详细角色卡由 DM 自行管理；这里使用绵羊生物卡并把智力/感知替换为法师属性。")
                .bookUI(10)
                .foregroundStyle(.secondary)
        }
    }

    private func playerInfo(_ member: PartyMember) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Lv \(member.level) · \(member.role)")
                .bookUI(12)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                info("先攻", signed(combatant.initiative))
                info("被动感知", "\(member.passivePerception)")
                info("临时 HP", "\(combatant.tempHP ?? 0)")
            }
            if !combatant.conditions.isEmpty {
                Text("状态：\(combatant.conditions.joined(separator: "、"))")
                    .bookUI(11)
                    .foregroundStyle(Theme.red)
            }
            if let concentration = combatant.concentration, !concentration.isEmpty {
                Text("专注：\(concentration)").bookUI(11).foregroundStyle(Theme.red)
            }
            Text("玩家角色卡由玩家自行管理；这里只显示当前战斗需要的数值。")
                .bookUI(10)
                .foregroundStyle(.secondary)
        }
    }

    private func info(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).bookUI(9).foregroundStyle(.secondary)
            Text(value).bookUI(12, monospaced: true)
        }
    }

    private func ability(_ label: String, _ value: Int) -> some View {
        let mod = Int(floor(Double(value - 10) / 2.0))
        return VStack(spacing: 1) {
            Text(label).bookUI(9).foregroundStyle(.secondary)
            Text("\(value)").bookUI(12, weight: .semibold)
            Text(mod >= 0 ? "+\(mod)" : "\(mod)").bookUI(9).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
