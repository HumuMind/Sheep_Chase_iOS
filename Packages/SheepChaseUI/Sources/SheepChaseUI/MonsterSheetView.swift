import SwiftUI
import SheepChaseCore

public struct MonsterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let monster: ContentPack.Monster
    let annotation: DMAnnotation?
    let onAnnotationSave: ((String, DMAnnotationMode) -> Void)?
    let onAnnotationDelete: (() -> Void)?
    let override: RunMonsterOverride?
    let onOverrideSave: ((Int, Int, Int, String) -> Void)?
    let onOverrideClear: (() -> Void)?

    public init(
        monster: ContentPack.Monster,
        annotation: DMAnnotation? = nil,
        onAnnotationSave: ((String, DMAnnotationMode) -> Void)? = nil,
        onAnnotationDelete: (() -> Void)? = nil,
        override: RunMonsterOverride? = nil,
        onOverrideSave: ((Int, Int, Int, String) -> Void)? = nil,
        onOverrideClear: (() -> Void)? = nil
    ) {
        self.monster = monster
        self.annotation = annotation
        self.onAnnotationSave = onAnnotationSave
        self.onAnnotationDelete = onAnnotationDelete
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

                    if let onAnnotationSave, let onAnnotationDelete {
                        DMAnnotationEditor(
                            subject: monster.name,
                            annotation: annotation,
                            onSave: onAnnotationSave,
                            onDelete: onAnnotationDelete
                        )
                    }
                }
                .padding(24)
                .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
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
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
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
