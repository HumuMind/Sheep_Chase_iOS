import SwiftUI

struct RunView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @State private var showAddPlayer = false
    @State private var showPrivacy = false
    @State private var showInspector = true

    private var currentScene: ContentPack.AdventureScene {
        store.currentScene(for: run)
    }

    private var sceneSelection: Binding<String?> {
        Binding(
            get: { run.sceneID },
            set: { newValue in
                guard let newValue, let scene = store.scene(id: newValue) else { return }
                store.selectScene(scene, in: run)
            }
        )
    }

    private var modeSelection: Binding<RunMode> {
        Binding(
            get: { run.mode },
            set: { store.setMode($0, in: run) }
        )
    }

    var body: some View {
        NavigationSplitView {
            List(selection: sceneSelection) {
                Section("场景") {
                    ForEach(store.scenes) { scene in
                        Text("\(scene.order). \(scene.title)")
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .padding(.vertical, 2)
                            .tag(scene.id)
                    }
                }

                Section("本团") {
                    LabeledContent("队伍", value: "\(run.party.count) 人")
                    LabeledContent("便签", value: "\(run.stickyNotes.count) 张")
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(.clear)
            .bookPaperSurface()
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 9) {
                    Image("Cover")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("荒野逐羊")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(run.name)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.clear)
                .overlay(alignment: .bottom) {
                    Divider().opacity(0.45)
                }
            }
            .navigationTitle("场景")
        } detail: {
            Group {
                if run.mode == .battle {
                    BattleCenterView(run: run)
                } else {
                    SceneDetailView(run: run)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.clear)
            .bookPaperSurface()
            .navigationTitle(run.mode == .battle ? "战斗" : "场景 \(currentScene.order)")
            .macNavigationSubtitle(run.mode == .battle ? run.name : "\(run.name) · \(currentScene.title)")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        store.closeRun()
                    } label: {
                        Label("我的开团", systemImage: "chevron.left")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Picker("视图", selection: modeSelection) {
                        ForEach(RunMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                if let battle = run.battle, battle.phase == .active {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            store.nextTurn(in: run)
                        } label: {
                            Label("下一回合", systemImage: "arrow.right")
                        }
                        Button {
                            store.endBattle(in: run)
                        } label: {
                            Label("结束战斗", systemImage: "flag.checkered")
                        }
                    }
                }

                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Label("检查器", systemImage: "sidebar.right")
                    }
                    Button {
                        showPrivacy = true
                    } label: {
                        Label("遮屏", systemImage: "eye.slash")
                    }
                    .help("临时遮挡 DM 内容")
                }
            }
        }
        .inspector(isPresented: $showInspector) {
            InspectorView(run: run, showAddPlayer: $showAddPlayer)
                .inspectorColumnWidth(min: 290, ideal: 320, max: 380)
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Theme.red)
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerSheet(run: run)
                .environment(store)
        }
        .overlay {
            if showPrivacy {
                ZStack {
                    Color.black.opacity(0.96)
                        .ignoresSafeArea()
                    VStack(spacing: 8) {
                        Text("已遮屏")
                            .font(.title2)
                            .tracking(4)
                        Text("点击任意处恢复")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .contentShape(Rectangle())
                .onTapGesture { showPrivacy = false }
            }
        }
    }
}
