import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct PartyInspector: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @Binding var showAddPlayer: Bool
    @State private var editingMember: PartyMember?
    @State private var removingMember: PartyMember?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("队伍")
                    .bookUI(13, weight: .semibold)
                Spacer()
                Text("\(run.party.count) 人")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
            }

            Button {
                showAddPlayer = true
            } label: {
                Label("添加玩家", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)

            if run.party.isEmpty {
                ContentUnavailableView {
                    Label("还没有玩家", systemImage: "person.badge.plus")
                } description: {
                    Text("新建开团是空白的。添加姓名、等级、AC、HP、先攻和被动感知即可。")
                }
                .controlSize(.small)
            } else {
                VStack(spacing: 0) {
                    ForEach(run.party) { member in
                        PartyRowView(
                            member: member,
                            onEdit: { editingMember = member },
                            onRemove: { removingMember = member }
                        )
                        if member.id != run.party.last?.id {
                            Divider()
                        }
                    }
                }
            }

            Text("只记录战斗需要的最小数值；不管理角色卡、升级或法术位。")
                .bookUI(10)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .sheet(item: $editingMember) { member in
            AddPlayerSheet(run: run, member: member)
                .environment(store)
        }
        .alert("移除玩家？", isPresented: Binding(
            get: { removingMember != nil },
            set: { if !$0 { removingMember = nil } }
        )) {
            Button("取消", role: .cancel) { removingMember = nil }
            Button("移除", role: .destructive) {
                if let member = removingMember {
                    store.removePlayer(member, from: run)
                }
                removingMember = nil
            }
        } message: {
            Text("会从当前开团移除 \(removingMember?.name ?? "该玩家")；战斗进行中不能移除。")
        }
    }
}
struct PartyRowView: View {
    let member: PartyMember
    var onEdit: () -> Void = {}
    var onRemove: () -> Void = {}

    private var hpColor: Color {
        let ratio = member.maxHP > 0 ? Double(member.hp) / Double(member.maxHP) : 0
        if ratio <= 0.25 { return Theme.redSoft }
        if ratio <= 0.5 { return Theme.amber }
        return Theme.green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(member.name)
                    .bookUI(13, weight: .medium)
                Text("Lv \(member.level) · \(member.role)")
                    .bookUI(11)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(member.hp)/\(member.maxHP)")
                    .bookUI(11, monospaced: true)
                    .foregroundStyle(.secondary)
                Menu {
                    Button("编辑资料…") { onEdit() }
                    Button("移除玩家", role: .destructive) { onRemove() }
                } label: {
                    Image(systemName: "ellipsis")
                        .bookUI(11)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 18)
                .accessibilityLabel("玩家操作")
            }

            ProgressView(value: Double(member.hp), total: Double(max(member.maxHP, 1)))
                .tint(hpColor)
                .controlSize(.small)

            HStack(spacing: 8) {
                Text("AC \(member.ac)")
                Text("被动 \(member.passivePerception)")
                Text("先攻 \(member.initMod >= 0 ? "+" : "")\(member.initMod)")
                if let tempHP = member.tempHP, tempHP > 0 {
                    Text("临时 HP \(tempHP)")
                        .foregroundStyle(.blue)
                }
                if !member.conditions.isEmpty {
                    Text(member.conditions.joined(separator: "、"))
                        .foregroundStyle(.orange)
                }
                Spacer()
            }
            .bookUI(10)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}
