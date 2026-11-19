import SheepChaseCore
import SheepChaseGuideFeature
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseSearchFeature
import SheepChaseUI
import SwiftUI
import UniformTypeIdentifiers

public struct LibraryView: View {
    public init() {}
    @Environment(RunStore.self) private var store
    @State private var selection: UUID?
    @State private var showNewRun = false
    @State private var showTemplates = false
    @State private var showImporter = false
    @State private var showAbout = false
    @State private var showSearch = false
    @State private var showGuide = false
    @State private var importError: String?

    private var selectedRun: RunRecord? {
        guard let selection else { return nil }
        return store.runs.first { $0.id == selection }
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("开团") {
                    ForEach(store.orderedRuns) { run in
                        LibraryRunRow(run: run)
                            .tag(run.id)
                    }
                }

                if !store.archivedRuns.isEmpty {
                    Section("已归档") {
                        ForEach(store.archivedRuns) { run in
                            LibraryRunRow(run: run)
                                .tag(run.id)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(.clear)
            .bookPaperSurface()
            .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 9) {
                    SheepChaseImages.sheep
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .opacity(0.9)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("荒野逐羊")
                            .bookSerif(15, weight: .bold)
                            .foregroundStyle(Theme.red)
                        Text("DM 工作台")
                            .bookUI(10)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.clear)
                .overlay(alignment: .bottom) {
                    Divider().opacity(0.45)
                }
            }
            .navigationTitle("我的开团")
        } detail: {
            Group {
                if let run = selectedRun {
                    LibraryRunDetail(run: run)
                } else {
                VStack(spacing: 12) {
                    SheepChaseImages.sheep
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .opacity(0.8)
                    Text("选择一场开团")
                        .bookUI(16, weight: .semibold)
                    Text("从左侧选择存档，或新建一场开团。")
                        .bookUI(12)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showSearch = true
                    } label: {
                        Label("全局速查", systemImage: "magnifyingglass")
                    }
                    .keyboardShortcut("k", modifiers: .command)

                    Button {
                        showGuide = true
                    } label: {
                        Label("DM 导读", systemImage: "book.closed")
                    }
                    .help("冒险摘要、引钩、背景与主持建议")

                    Button {
                        showNewRun = true
                    } label: {
                        Label("新建开团", systemImage: "plus")
                    }
                    .help("新建开团")

                    Button {
                        showTemplates = true
                    } label: {
                        Label("我的模组", systemImage: "square.stack.3d.up")
                    }
                    .help("管理已保存的模组")

                    Button {
                        showImporter = true
                    } label: {
                        Label("导入开团备份", systemImage: "square.and.arrow.down")
                    }
                    .help("导入开团备份")

                    Button {
                        showAbout = true
                    } label: {
                        Label("关于内容包", systemImage: "info.circle")
                    }
                    .help("关于内容包")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Theme.red)
        .sheet(isPresented: $showNewRun) {
            NewRunSheet()
                .environment(store)
        }
        .sheet(isPresented: $showTemplates) {
            TemplateLibrarySheet()
                .environment(store)
        }
        .sheet(isPresented: $showAbout) {
            AboutContentSheet(content: store.content)
                .environment(store)
        }
        .sheet(isPresented: $showGuide) {
            AdventureGuideView(content: store.content)
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView(run: nil)
                .environment(store)
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                do {
                    let data = try Data(contentsOf: url)
                    _ = try store.importRun(from: data)
                    selection = store.selectedRunID
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert("导入失败", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好") { importError = nil }
        } message: {
            Text(importError ?? "未知错误")
        }
        .onAppear {
            if selection == nil {
                selection = store.orderedRuns.first?.id ?? store.archivedRuns.first?.id
            }
        }
    }
}
