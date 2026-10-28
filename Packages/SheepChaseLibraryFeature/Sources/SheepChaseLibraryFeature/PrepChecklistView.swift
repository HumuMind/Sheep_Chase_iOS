import SheepChaseSearchFeature
import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct PrepChecklistView: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Bindable var run: RunRecord

    private var totalItems: Int {
        store.scenes.count + store.npcs.count + store.content.monsters.count + store.handouts.count + store.maps.count + 1
    }

    private var checkedCount: Int {
        run.prepChecks.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("备团进度")
                            .font(.headline)
                        Spacer()
                        Text("\(min(checkedCount, totalItems)) / \(totalItems)")
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(min(checkedCount, totalItems)), total: Double(max(totalItems, 1)))
                        .tint(Theme.red)
                    Text("可选清单：读场景、看 NPC/怪物、设队伍、备手牌。不会自动改剧情或战斗状态。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("场景") {
                    ForEach(store.scenes) { scene in
                        check("scene:\(scene.id)", "\(scene.order). \(scene.title)", detail: scene.summary)
                    }
                }

                Section("NPC") {
                    ForEach(store.npcs) { npc in
                        check("npc:\(npc.id)", npc.name, detail: npc.role)
                    }
                }

                Section("怪物") {
                    ForEach(store.content.monsters.sorted { $0.name < $1.name }) { monster in
                        check("monster:\(monster.id)", monster.name, detail: "AC \(monster.ac.value) · HP \(monster.hp.average)")
                    }
                }

                Section("手牌与地图") {
                    ForEach(store.handouts) { handout in
                        check("handout:\(handout.id)", handout.title, detail: nil)
                    }
                    ForEach(store.maps) { map in
                        check("map:\(map.id)", map.title, detail: "\(map.pins.count) 个图钉")
                    }
                }

                Section("队伍") {
                    check("party", "队伍已录入", detail: "\(run.party.count) 人")
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(Theme.readingPaper)
            .environment(\.colorScheme, .light)
            .navigationTitle("备团清单")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("清空") {
                        store.clearPrep(in: run)
                    }
                    .disabled(run.prepChecks.isEmpty)
                }
            }
        }
        .frame(minWidth: 540, minHeight: 600)
    }

    private func check(_ id: String, _ title: String, detail: String?) -> some View {
        Toggle(isOn: Binding(
            get: { store.isPrepChecked(id, in: run) },
            set: { _ in store.togglePrep(id, in: run) }
        )) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.body)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
