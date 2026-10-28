import SwiftUI
import SheepChaseCore

public struct MonsterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let monster: ContentPack.Monster

    public init(monster: ContentPack.Monster) {
        self.monster = monster
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(monster.name)
                                .font(.largeTitle.weight(.semibold))
                            Text("\(monster.size)\(monster.type) · \(monster.alignment)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("CR \(monster.challenge.rating.formatted()) · \(monster.challenge.xp) XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    GroupBox("防御与属性") {
                        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 4) {
                            GridRow {
                                Label("AC \(monster.ac.value)", systemImage: "shield")
                                Label("HP \(monster.hp.average)（\(monster.hp.formula)）", systemImage: "heart")
                            }
                            GridRow {
                                Text("速度 步行 \(monster.speed.walk) 尺\(monster.speed.climb.map { " · 攀爬 \($0) 尺" } ?? "")\(monster.speed.fly.map { " · 飞行 \($0) 尺" } ?? "")")
                                Text("被动感知 \(monster.senses?.passivePerception ?? 0)")
                            }
                        }
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 3)
                    }

                    GroupBox("六项属性") {
                        HStack(spacing: 14) {
                            ability("力量", monster.abilities.str)
                            ability("敏捷", monster.abilities.dex)
                            ability("体质", monster.abilities.con)
                            ability("智力", monster.abilities.int)
                            ability("感知", monster.abilities.wis)
                            ability("魅力", monster.abilities.cha)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 3)
                    }

                    if let traits = monster.traits, !traits.isEmpty {
                        GroupBox("特性") {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(traits) { trait in
                                    Text("**\(trait.name)。** \(trait.text)")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }

                    GroupBox("动作") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(monster.actions) { action in
                                Text("**\(action.name)。** \(action.text)")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }

                    if let vulnerabilities = monster.damageVulnerabilities, !vulnerabilities.isEmpty {
                        GroupBox("易伤") {
                            Text(vulnerabilities.joined(separator: "、"))
                                .font(.callout)
                                .foregroundStyle(Theme.red)
                        }
                    }

                    if let tactics = monster.tactics, !tactics.isEmpty {
                        GroupBox("战术") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(tactics, id: \.self) { tactic in
                                    Text("· \(tactic)")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }

                    if let sourceRef = monster.sourceRef {
                        Text(sourceRef)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: 680, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(BookPaperBackground())
            .navigationTitle(monster.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 540, minHeight: 520)
    }

    private func ability(_ name: String, _ value: Int) -> some View {
        VStack(spacing: 1) {
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.callout.monospacedDigit().weight(.semibold))
            Text(abilityModifier(value))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func abilityModifier(_ value: Int) -> String {
        let mod = Int(floor(Double(value - 10) / 2.0))
        return mod >= 0 ? "+\(mod)" : "\(mod)"
    }
}
