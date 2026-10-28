import SwiftUI
import UniformTypeIdentifiers

struct RunView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @State private var showAddPlayer = false
    @State private var showPrivacy = false
    @State private var showInspector = true
    @State private var selectedNPC: ContentPack.NPC?
    @State private var selectedHandout: ContentPack.Handout?
    @State private var selectedItem: ContentPack.Item?
    @State private var selectedRule: ContentPack.RuleCard?
    @State private var selectedSpell: ContentPack.SpellCard?
    @State private var selectedMonster: ContentPack.Monster?
    @State private var showSearch = false
    @State private var showSessions = false
    @State private var showSafety = false
    @State private var showImageExport = false
    @State private var showLeaveConfirmation = false
    @State private var showExporter = false
    @State private var exportDocument: RunExportDocument?
    @State private var exportContentType: UTType = .json
    @State private var exportFilename = "荒野逐羊_开团备份.json"
    @State private var exportError: String?

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
                } else if run.mode == .map {
                    MapView(run: run)
                } else {
                    SceneDetailView(
                        run: run,
                        onOpenNPC: { npcID in
                            selectedNPC = store.npc(id: npcID)
                        },
                        onOpenHandout: { handoutID in
                            selectedHandout = store.handout(id: handoutID)
                        },
                        onOpenItem: { itemID in
                            selectedItem = store.item(id: itemID)
                        },
                        onOpenRule: { ruleID in
                            selectedRule = store.rule(id: ruleID)
                        },
                        onOpenSpell: { spellID in
                            selectedSpell = store.spell(id: spellID)
                        },
                        onOpenMonster: { monsterID in
                            selectedMonster = store.monster(id: monsterID)
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.clear)
            .bookPaperSurface()
            .navigationTitle(run.mode == .battle ? "战斗" : (run.mode == .map ? "地图" : "场景 \(currentScene.order)"))
            .macNavigationSubtitle(run.mode == .battle ? run.name : (run.mode == .map ? "\(run.name) · \(store.maps.first?.title ?? "")" : "\(run.name) · \(currentScene.title)"))
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        if let battle = run.battle, battle.phase == .active {
                            showLeaveConfirmation = true
                        } else {
                            store.closeRun()
                        }
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
                    .frame(width: 230)
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
                        showSearch = true
                    } label: {
                        Label("全局速查", systemImage: "magnifyingglass")
                    }
                    .keyboardShortcut("k", modifiers: .command)

                    Menu {
                        Button {
                            exportJSON()
                        } label: {
                            Label("导出开团备份（JSON）", systemImage: "doc.badge.arrow.up")
                        }
                        Button {
                            exportMarkdown()
                        } label: {
                            Label("导出日志（Markdown）", systemImage: "text.document")
                        }
                        Divider()
                        Button {
                            showImageExport = true
                        } label: {
                            Label("导出模组图片…", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Label("导出", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showSessions = true
                    } label: {
                        Label("聚会记录", systemImage: "calendar.badge.clock")
                    }
                    .help("聚会记录与本地快照")

                    Button {
                        showSafety = true
                    } label: {
                        Label("安全工具", systemImage: "shield.lefthalf.filled")
                    }
                    .help("桌面安全、lines/veils 与暂停暗号")

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
        .sheet(item: $selectedNPC) { npc in
            NPCSheetView(npc: npc)
                .environment(store)
        }
        .sheet(item: $selectedHandout) { handout in
            HandoutSheetView(
                handout: handout,
                asset: handout.imageAssetId.flatMap { store.asset(id: $0) }
            )
            .environment(store)
        }
        .sheet(item: $selectedItem) { item in
            ItemSheetView(item: item)
                .environment(store)
        }
        .sheet(item: $selectedRule) { rule in
            RuleSheetView(rule: rule)
                .environment(store)
        }
        .sheet(item: $selectedSpell) { spell in
            SpellSheetView(spell: spell)
                .environment(store)
        }
        .sheet(item: $selectedMonster) { monster in
            MonsterSheetView(monster: monster)
                .environment(store)
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView(run: run)
                .environment(store)
        }
        .sheet(isPresented: $showSessions) {
            SessionLogView(run: run)
                .environment(store)
        }
        .sheet(isPresented: $showSafety) {
            SafetySheet(run: run)
                .environment(store)
        }
        .sheet(isPresented: $showImageExport) {
            ImageExportView()
                .environment(store)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { result in
            if case let .failure(error) = result {
                exportError = error.localizedDescription
            }
        }
        .alert("导出失败", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("好") { exportError = nil }
        } message: {
            Text(exportError ?? "未知错误")
        }
        .alert("离开战斗？", isPresented: $showLeaveConfirmation) {
            Button("留在战斗", role: .cancel) {}
            Button("离开并保存") { store.closeRun() }
        } message: {
            Text("当前战斗状态会保留，下次打开这个开团可以继续。")
        }
        .task {
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-demoNPC") {
                selectedNPC = store.npc(id: "ahmed-noke")
            }
            if args.contains("-demoHandout") {
                selectedHandout = store.handout(id: "scroll-speak-with-animals")
            }
            if args.contains("-demoItem") {
                selectedItem = store.item(id: "staff-of-true-polymorph")
            }
            if args.contains("-demoSafety") {
                showSafety = true
            }
            if args.contains("-demoSessions") {
                showSessions = true
            }
            if args.contains("-demoSearch") {
                showSearch = true
            }
            if args.contains("-demoImageExport") {
                showImageExport = true
            }
            #endif
        }
        .overlay {
            if showPrivacy {
                ZStack {
                    Color.black.opacity(0.96)
                        .ignoresSafeArea()
                    VStack(spacing: 10) {
                        Text("已遮屏")
                            .font(.title2)
                            .tracking(4)
                        Text("点击任意处恢复")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("记录休息并恢复") {
                            store.recordRest(note: "暂停遮屏", in: run)
                            showPrivacy = false
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .contentShape(Rectangle())
                .onTapGesture { showPrivacy = false }
            }
        }
    }

    private func exportJSON() {
        do {
            let data = try store.exportJSON(for: run)
            exportDocument = RunExportDocument(data: data)
            exportContentType = .json
            exportFilename = RunExport.safeFilename(run.name, suffix: "开团备份", extension: "json")
            showExporter = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportMarkdown() {
        let markdown = store.exportMarkdown(for: run)
        exportDocument = RunExportDocument(data: Data(markdown.utf8))
        exportContentType = .plainText
        exportFilename = RunExport.safeFilename(run.name, suffix: "日志", extension: "md")
        showExporter = true
    }
}
