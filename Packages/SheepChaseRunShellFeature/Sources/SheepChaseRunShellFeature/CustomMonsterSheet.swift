import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct CustomMonsterSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord

    @State private var name = ""
    @State private var size = "中型"
    @State private var type = "怪兽"
    @State private var alignment = "无阵营"
    @State private var ac = 13
    @State private var hp = 20
    @State private var initiativeModifier = 0
    @State private var actionText = ""

    var body: some View {
        BookFormSheet(
            title: "自定义怪物",
            primaryTitle: "添加",
            primaryDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onCancel: { dismiss() },
            onPrimary: add
        ) {
            BookFormSection("身份") {
                BookTextField("名称", text: $name)
                HStack(spacing: 10) {
                    BookTextField("体型", text: $size)
                    BookTextField("类型", text: $type)
                }
                BookTextField("阵营", text: $alignment)
            }
            BookFormSection("数值") {
                Stepper("护甲等级  \(ac)", value: $ac, in: 1...40)
                    .bookSerif(14)
                Stepper("生命值  \(hp)", value: $hp, in: 1...999)
                    .bookSerif(14)
                Stepper("先攻调整  \(initiativeModifier >= 0 ? "+" : "")\(initiativeModifier)", value: $initiativeModifier, in: -5...10)
                    .bookSerif(14)
            }
            BookFormSection("动作") {
                BookTextEditor("这个怪物在战斗中做什么……", text: $actionText, minHeight: 100)
            }
            Text("自定义怪物只存在于当前开团，可在战斗筹备中选择。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func add() {
        store.addCustomMonster(
            name: name,
            size: size,
            type: type,
            alignment: alignment,
            ac: ac,
            hp: hp,
            initiativeModifier: initiativeModifier,
            actionText: actionText,
            in: run
        )
        dismiss()
    }
}
