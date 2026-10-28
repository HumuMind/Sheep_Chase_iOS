import SwiftUI

struct BattleCenterView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    var body: some View {
        Group {
            if let battle = run.battle {
                switch battle.phase {
                case .select:
                    BattleSelectView(run: run)
                case .initiative:
                    BattleInitiativeView(run: run)
                case .active:
                    BattleActiveView(run: run)
                }
            } else {
                ContentUnavailableView {
                    Label("还没有战斗筹备", systemImage: "shield")
                } description: {
                    Text("从场景遭遇进入，或点击下方按钮开始。")
                } actions: {
                    Button("开始战斗筹备") {
                        store.openBattleSetup(for: run)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)
                }
            }
        }
    }
}
