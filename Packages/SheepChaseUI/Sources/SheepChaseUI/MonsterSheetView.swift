import SheepChaseCore
import SwiftUI

public struct MonsterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let monster: ContentPack.Monster
    let annotations: [DMAnnotation]
    let onAnnotationChange: (([DMAnnotation]) -> Void)?
    let override: RunMonsterOverride?
    let onOverrideSave: ((Int, Int, Int, String) -> Void)?
    let onOverrideClear: (() -> Void)?

    public init(
        monster: ContentPack.Monster,
        annotations: [DMAnnotation] = [],
        onAnnotationChange: (([DMAnnotation]) -> Void)? = nil,
        override: RunMonsterOverride? = nil,
        onOverrideSave: ((Int, Int, Int, String) -> Void)? = nil,
        onOverrideClear: (() -> Void)? = nil
    ) {
        self.monster = monster
        self.annotations = annotations
        self.onAnnotationChange = onAnnotationChange
        self.override = override
        self.onOverrideSave = onOverrideSave
        self.onOverrideClear = onOverrideClear
        _ac = State(initialValue: override?.ac ?? monster.ac.value)
        _hp = State(initialValue: override?.hp ?? monster.hp.average)
        _initMod = State(initialValue: override?.initiativeModifier ?? monster.initiativeModifier)
        _overrideNote = State(initialValue: override?.note ?? "")
    }

    @State private var ac: Int
    @State private var hp: Int
    @State private var initMod: Int
    @State private var overrideNote: String

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(monster.name)
                                .bookUI(28, weight: .semibold)
                            Text("\(monster.size)\(monster.type) · \(monster.alignment)")
                                .bookUI(12)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("CR \(monster.challenge.rating.formatted()) · \(monster.challenge.xp) XP")
                            .bookUI(11)
                            .foregroundStyle(.secondary)
                    }

                    if let onOverrideSave, let onOverrideClear {
                        GroupBox("本场数值调整") {
                            VStack(alignment: .leading, spacing: 8) {
                                Stepper("AC \(ac)", value: $ac, in: 1...40)
                                Stepper("HP \(hp)", value: $hp, in: 1...999)
                                Stepper("先攻调整 \(initMod >= 0 ? "+" : "")\(initMod)", value: $initMod, in: -10...15)
                                TextField("调整备注（可选）", text: $overrideNote)
                                    .textFieldStyle(.roundedBorder)
                                HStack {
                                    Button("保存本场调整") {
                                        onOverrideSave(ac, hp, initMod, overrideNote)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Theme.red)
                                    Button("恢复原始") {
                                        onOverrideClear()
                                        ac = monster.ac.value
                                        hp = monster.hp.average
                                        initMod = monster.initiativeModifier
                                        overrideNote = ""
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.vertical, 3)
                        }
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
                        .bookUI(12)
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
                                        .bookUI(12)
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
                                    .bookUI(12)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                    }

                    if let vulnerabilities = monster.damageVulnerabilities, !vulnerabilities.isEmpty {
                        GroupBox("易伤") {
                            Text(vulnerabilities.joined(separator: "、"))
                                .bookUI(12)
                                .foregroundStyle(Theme.red)
                        }
                    }

                    if let tactics = monster.tactics, !tactics.isEmpty {
                        GroupBox("战术") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(tactics, id: \.self) { tactic in
                                    Text("· \(tactic)")
                                        .bookUI(12)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 3)
                        }
                    }

                    if let sourceRef = monster.sourceRef {
                        Text(sourceRef)
                            .bookUI(11)
                            .foregroundStyle(.secondary)
                    }

                    if let onAnnotationChange {
                        DMAnnotationEditor(
                            subject: monster.name,
                            targetKind: .monster,
                            targetID: monster.id,
                            annotations: annotations,
                            onChange: onAnnotationChange
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Theme.sheetBackground)
            .navigationTitle(monster.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
    }

    private func ability(_ name: String, _ value: Int) -> some View {
        VStack(spacing: 1) {
            Text(name)
                .bookUI(10)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .bookUI(12, weight: .semibold, monospaced: true)
            Text(abilityModifier(value))
                .bookUI(10)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func abilityModifier(_ value: Int) -> String {
        let mod = Int(floor(Double(value - 10) / 2.0))
        return mod >= 0 ? "+\(mod)" : "\(mod)"
    }
}
