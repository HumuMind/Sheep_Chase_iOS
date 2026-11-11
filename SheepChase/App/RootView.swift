import SheepChaseRunShellFeature
import SheepChaseLibraryFeature
import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct RootView: View {
    @Environment(RunStore.self) private var store
    @AppStorage("appTextSize") private var appTextSize = AppTextSize.large.rawValue

    var body: some View {
        ZStack(alignment: .bottom) {
            BookPaperBackground()

            Group {
                if let run = store.selectedRun {
                    RunView(run: run)
                } else {
                    LibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.clear)
            .groupBoxStyle(BookGroupBoxStyle())

            if let toast = store.toast {
                Text(toast)
                    .bookUI(12, weight: .medium)
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.18), radius: 16, y: 7)
                    .padding(.bottom, 22)
            }
        }
        .tint(Theme.red)
        .dynamicTypeSize((AppTextSize(rawValue: appTextSize) ?? .large).dynamicTypeSize)
        .themedToolbarBackground()
        .dismissFocusOnBackgroundClick()
        .task {
            openDemoRunIfNeeded()
        }
    }

    private func openDemoRunIfNeeded() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-demoRun"),
              let run = store.orderedRuns.first(where: { $0.name.contains("周五") }) ?? store.orderedRuns.first
        else { return }

        store.open(run)
        if arguments.contains("-resetPins") {
            for id in run.pinnedReferenceIDs {
                store.togglePinnedReference(id, in: run)
            }
        }
        if arguments.contains("-demoScene") {
            store.setMode(.scene, in: run)
        }
        if arguments.contains("-demoMap") {
            store.setMode(.map, in: run)
        }
        if arguments.contains("-demoScene2"), let scene = store.scene(id: "scene-2") {
            store.selectScene(scene, in: run)
        }
        if arguments.contains("-demoScene3"), let scene = store.scene(id: "scene-3") {
            store.selectScene(scene, in: run)
        }
        if arguments.contains("-demoScene4"), let scene = store.scene(id: "scene-4") {
            store.selectScene(scene, in: run)
        }

        if arguments.contains("-demoNotes") {
            store.selectedTab = .notes
        }

        if arguments.contains("-demoBattleActive") {
            store.openBattleSetup(for: run)
            run.party.forEach { store.toggleBattlePlayer($0, in: run) }
            if let guz = store.content.monsters.first(where: { $0.id == "guz" }) {
                store.addBattleMonster(guz, in: run)
            }
            if let wolf = store.content.monsters.first(where: { $0.id == "wolf-guard" }) {
                for _ in 0..<3 { store.addBattleMonster(wolf, in: run) }
            }
            if let bear = store.content.monsters.first(where: { $0.id == "brown-bear" }) {
                store.addBattleMonster(bear, in: run)
            }
            store.goToInitiative(in: run)
            for (index, member) in run.party.enumerated() {
                store.setPlayerInitiative(String(20 - index), memberID: member.id, in: run)
            }
            store.startBattle(in: run)
        } else if arguments.contains("-demoBattle") {
            store.openBattleSetup(for: run)
        }
        #endif
    }
}
