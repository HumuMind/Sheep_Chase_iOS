import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct BattleStepsView: View {
    let phase: BattlePhase

    var body: some View {
        HStack(spacing: 18) {
            step(number: 1, title: "选择参战者", active: phase == .select)
            step(number: 2, title: "填写先攻", active: phase == .initiative)
            step(number: 3, title: "按轮次战斗", active: phase == .active)
        }
        .padding(.vertical, 2)
    }

    private func step(number: Int, title: String, active: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: active ? "\(number).circle.fill" : "\(number).circle")
                .foregroundStyle(active ? Theme.red : .secondary)
            Text(title)
                .bookUI(12, weight: active ? .medium : .regular)
                .foregroundStyle(active ? .primary : .secondary)
        }
    }
}

struct PlayerSelectionRow: View {
    let member: PartyMember
    let selected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(String(member.name.prefix(1)))
                .bookUI(11, weight: .semibold)
                .frame(width: 24, height: 24)
                .background(.quaternary, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(member.name)
                    .bookUI(13, weight: .medium)
                Text("Lv \(member.level) · \(member.role)")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(selected ? "已加入" : "添加") {
                action()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 5)
    }
}
