import SheepChaseBattleFeature
import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

public struct InspectorView: View {
    public init(run: RunRecord, showAddPlayer: Binding<Bool>) {
        self.run = run
        self._showAddPlayer = showAddPlayer
    }

    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @Binding var showAddPlayer: Bool

    private var tabSelection: Binding<InspectorTab> {
        Binding(
            get: { store.selectedTab },
            set: { tab in
                if tab == .battle {
                    store.setMode(.battle, in: run)
                } else {
                    store.selectedTab = tab
                }
            }
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            Picker("检查器", selection: tabSelection) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)

            Divider()

            ScrollView {
                Group {
                    switch store.selectedTab {
                    case .party:
                        PartyInspector(run: run, showAddPlayer: $showAddPlayer)
                    case .battle:
                        BattleInspector(run: run)
                    case .notes:
                        NotesInspector(run: run)
                    case .rules:
                        RulesInspector()
                    }
                }
                .padding(14)
            }
        }
        .background(Theme.readingPaper)
        .environment(\.colorScheme, .light)
    }
}
