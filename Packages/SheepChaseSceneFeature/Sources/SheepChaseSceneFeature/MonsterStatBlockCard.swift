import SheepChaseCore
import SheepChaseUI
import SwiftUI

struct MonsterStatBlockCard: View {
    let monster: ContentPack.Monster

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monster.name)
                .font(Theme.serif(22, weight: .semibold))
                .foregroundStyle(Theme.red)
            Text("\(monster.size)\(monster.type)，\(monster.alignment)")
                .font(Theme.serif(11))
                .foregroundStyle(Theme.inkSoft)

            Rectangle().fill(Theme.red.opacity(0.8)).frame(height: 1.5)

            VStack(alignment: .leading, spacing: 3) {
                Text("护甲等级 \(monster.ac.value)\(monster.ac.note.map { "（\($0)）" } ?? "")")
                Text("生命值 \(monster.hp.average)（\(monster.hp.formula)）")
                Text("速度 \(speedText)")
            }
            .font(Theme.serif(12))
            .foregroundStyle(Theme.ink)

            abilityGrid

            VStack(alignment: .leading, spacing: 2) {
                if let skills = monster.skills, !skills.isEmpty {
                    Text("技能 \(skills.joined(separator: "、"))")
                }
                if let senses = monster.senses {
                    Text("感官 被动感知 \(senses.passivePerception)")
                }
                if let languages = monster.languages, !languages.isEmpty {
                    Text("语言 \(languages.joined(separator: "、"))")
                }
                Text("挑战等级 \(challengeRating)（\(monster.challenge.xp) XP）")
            }
            .font(Theme.serif(11))
            .foregroundStyle(Theme.inkSoft)

            Rectangle().fill(Theme.red.opacity(0.35)).frame(height: 0.7)

            if let traits = monster.traits {
                ForEach(traits) { trait in
                    Text("\(trait.name)。\(trait.text)")
                        .font(Theme.serif(11))
                        .foregroundStyle(Theme.ink)
                }
            }

            Text("动作")
                .font(Theme.serif(14, weight: .semibold))
                .foregroundStyle(Theme.red)
                .padding(.top, 2)

            ForEach(monster.actions) { action in
                Text("\(action.name)。\(action.text)")
                    .font(Theme.serif(11))
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.90, green: 0.87, blue: 0.81).opacity(0.64))
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.red.opacity(0.85)).frame(height: 2)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.red.opacity(0.85)).frame(height: 2)
        }
        .padding(.vertical, 8)
        .accessibilityIdentifier("monster-stat-block-\(monster.id)")
    }

    private var abilityGrid: some View {
        HStack(spacing: 0) {
            abilityCell("力量", monster.abilities.str)
            abilityCell("敏捷", monster.abilities.dex)
            abilityCell("体质", monster.abilities.con)
            abilityCell("智力", monster.abilities.int)
            abilityCell("感知", monster.abilities.wis)
            abilityCell("魅力", monster.abilities.cha)
        }
        .padding(.vertical, 4)
        .background(Theme.red.opacity(0.10))
    }

    private func abilityCell(_ label: String, _ score: Int) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(Theme.serif(9, weight: .semibold))
                .foregroundStyle(Theme.red)
            Text("\(score) (\(modifier(score)))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private func modifier(_ score: Int) -> String {
        let value = Int(floor(Double(score - 10) / 2.0))
        return value >= 0 ? "+\(value)" : "\(value)"
    }

    private var speedText: String {
        var parts = ["\(monster.speed.walk) 尺"]
        if let climb = monster.speed.climb { parts.append("攀爬 \(climb) 尺") }
        if let fly = monster.speed.fly { parts.append("飞行 \(fly) 尺") }
        return parts.joined(separator: "，")
    }

    private var challengeRating: String {
        let rating = monster.challenge.rating
        if rating == 0.125 { return "1/8" }
        if rating == 0.25 { return "1/4" }
        if rating == 0.5 { return "1/2" }
        return rating.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(rating))"
            : String(format: "%.2f", rating)
    }
}
