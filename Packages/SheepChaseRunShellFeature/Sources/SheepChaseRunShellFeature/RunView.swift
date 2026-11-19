import SheepChaseBattleFeature
import SheepChaseCore
import SheepChaseExport
import SheepChaseGuideFeature
import SheepChaseInspectorFeature
import SheepChaseMapFeature
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseSceneFeature
import SheepChaseSearchFeature
import SheepChaseUI
import SwiftUI
import UniformTypeIdentifiers

public struct RunView: View {
    public init(run: RunRecord) {
        self.run = run
    }
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @State private var showAddPlayer = false
    @State private var showPrivacy = false
    @State private var showInspector = true
    @State private var reference: RunReference?
    @State private var showSearch = false
    @State private var showGuide = false
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
    private var modeSelection: Binding<RunMode> {
        Binding(
            get: { run.mode },
            set: { store.setMode($0, in: run) }
        )
    }
    public var body: some View {
        NavigationSplitView {
            RunSidebar(run: run, showGuide: $showGuide)
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
                            reference = store.npc(id: npcID).map(RunReference.npc)
                        },
                        onOpenHandout: { handoutID in
                            reference = store.handout(id: handoutID).map(RunReference.handout)
                        },
                        onOpenItem: { itemID in
                            reference = store.item(id: itemID).map(RunReference.item)
                        },
                        onOpenRule: { ruleID in
                            reference = store.rule(id: ruleID).map(RunReference.rule)
                        },
                        onOpenSpell: { spellID in
                            reference = store.spell(id: spellID).map(RunReference.spell)
                        },
                        onOpenMonster: { monsterID in
                            reference = store.monster(id: monsterID).map(RunReference.monster)
                        },
                        onOpenGuide: { showGuide = true }
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
                        Label("主页", systemImage: "house")
                    }
                    .help("返回主页")
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
                        .keyboardShortcut(.rightArrow, modifiers: .command)
                        .help("下一回合（⌘→）")
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
        .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                QuickReferencePanel(run: run)
                    .padding(14)
                Spacer()
                DicePanel(run: run)
                    .padding(14)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Theme.red)
        .sheet(isPresented: $showAddPlayer) {
            AddPlayerSheet(run: run)
                .environment(store)
        }
        .sheet(item: $reference) { reference in
            RunReferenceSheet(reference: reference, run: run)
                .environment(store)
        }
        .sheet(isPresented: $showGuide) { AdventureGuideView(content: store.content) }
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
            if let npcID = DemoLaunch.npcID, let npc = store.npc(id: npcID) {
                reference = .npc(npc)
            }
            if let handoutID = DemoLaunch.handoutID, let handout = store.handout(id: handoutID) {
                reference = .handout(handout)
            }
            if let itemID = DemoLaunch.itemID, let item = store.item(id: itemID) {
                reference = .item(item)
            }
            if DemoLaunch.showsSafetySheet {
                showSafety = true
            }
            if DemoLaunch.showsSessionsSheet {
                showSessions = true
            }
            if DemoLaunch.showsSearchSheet {
                showSearch = true
            }
            if DemoLaunch.showsImageExport {
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
                            .bookUI(19)
                            .tracking(4)
                        Text("点击任意处恢复")
                            .bookUI(11)
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
