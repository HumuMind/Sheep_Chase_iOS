import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(RunStore.self) private var store
    @State private var selection: UUID?
    @State private var showNewRun = false
    @State private var showImporter = false
    @State private var showAbout = false
    @State private var showSearch = false
    @State private var importError: String?

    private var selectedRun: RunRecord? {
        guard let selection else { return nil }
        return store.runs.first { $0.id == selection }
    }

    var body: some View {
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
                    Image("Sheep")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .opacity(0.9)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("荒野逐羊")
                            .font(Theme.serif(15, weight: .bold))
                            .foregroundStyle(Theme.red)
                        Text("DM 工作台")
                            .font(.caption2)
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
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        showSearch = true
                    } label: {
                        Label("全局速查", systemImage: "magnifyingglass")
                    }
                    .keyboardShortcut("k", modifiers: .command)

                    Menu {
                        Button {
                            showNewRun = true
                        } label: {
                            Label("新建开团", systemImage: "plus")
                        }
                        Button {
                            showImporter = true
                        } label: {
                            Label("导入开团备份…", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("开团操作", systemImage: "plus")
                    }
                    Button {
                        showAbout = true
                    } label: {
                        Label("关于内容包", systemImage: "info.circle")
                    }
                }
            }
        } detail: {
            if let run = selectedRun {
                LibraryRunDetail(run: run)
            } else {
                VStack(spacing: 12) {
                    Image("Sheep")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .opacity(0.8)
                    Text("选择一场开团")
                        .font(.title3.weight(.semibold))
                    Text("从左侧选择存档，或新建一场开团。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Theme.red)
        .sheet(isPresented: $showNewRun) {
            NewRunSheet()
                .environment(store)
        }
        .sheet(isPresented: $showAbout) {
            AboutContentSheet(content: store.content)
                .environment(store)
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

private struct LibraryRunRow: View {
    @Environment(RunStore.self) private var store
    let run: RunRecord

    private var sceneIndex: Int {
        store.scenes.firstIndex { $0.id == run.sceneID } ?? 0
    }

    private var scene: ContentPack.AdventureScene? {
        store.scene(id: run.sceneID)
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.red.opacity(0.8))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(scene?.title ?? "未知场景")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text("\(sceneIndex + 1)/\(store.scenes.count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

private struct LibraryRunDetail: View {
    @Environment(RunStore.self) private var store
    let run: RunRecord
    @State private var showRename = false
    @State private var renameText = ""
    @State private var showDelete = false
    @State private var showPrep = false

    private var sceneIndex: Int {
        store.scenes.firstIndex { $0.id == run.sceneID } ?? 0
    }

    private var scene: ContentPack.AdventureScene? {
        store.scene(id: run.sceneID)
    }

    private var progress: Double {
        guard !store.scenes.isEmpty else { return 0 }
        return Double(sceneIndex + 1) / Double(store.scenes.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    Image("Cover")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 92, height: 126)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.secondary.opacity(0.22), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.adventure.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                        Text(run.name)
                            .font(.largeTitle.weight(.semibold))
                        Text("\(store.adventure.level.min)–\(store.adventure.level.max) 级 · \(store.adventure.players.min)–\(store.adventure.players.max) 人 · 约 \(store.adventure.durationMinutes) 分钟")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        if run.isArchived {
                            store.setArchived(false, in: run)
                        } else {
                            store.open(run)
                        }
                    } label: {
                        Label(run.isArchived ? "恢复开团" : "继续带团", systemImage: run.isArchived ? "archivebox" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        showPrep = true
                    } label: {
                        Label("备团清单", systemImage: "checklist")
                    }
                    .buttonStyle(.bordered)

                    Text("上次更新 \(run.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                GroupBox("进度") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(scene?.title ?? "未知场景")
                                .font(.body.weight(.medium))
                            Spacer()
                            Text("场景 \(sceneIndex + 1) / \(store.scenes.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: progress)
                            .tint(Theme.red)
                    }
                    .padding(.vertical, 4)
                }

                GroupBox("队伍") {
                    if run.party.isEmpty {
                        HStack {
                            Text("还没有玩家")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("打开开团添加") {
                                store.open(run)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(run.party) { member in
                                HStack {
                                    Text(member.name)
                                        .font(.body.weight(.medium))
                                    Text("Lv \(member.level) · \(member.role)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("AC \(member.ac) · HP \(member.hp)/\(member.maxHP)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 5)
                                if member.id != run.party.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                if !run.stickyNotes.isEmpty {
                    GroupBox("便签") {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(run.stickyNotes.prefix(3)) { note in
                                HStack(alignment: .top, spacing: 7) {
                                    Circle()
                                        .fill(noteColor(note.color))
                                        .frame(width: 7, height: 7)
                                        .padding(.top, 5)
                                    Text(note.text.isEmpty ? "空白便签" : note.text)
                                        .font(.callout)
                                        .foregroundStyle(note.text.isEmpty ? .secondary : .primary)
                                        .lineLimit(2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                GroupBox("内容提示") {
                    Text(store.adventure.contentWarnings.joined(separator: " · "))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 3)
                }
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
            .readingPage()
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(.clear)
        .bookPaperSurface()
        .navigationTitle("开团详情")
        .macNavigationSubtitle(store.adventure.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !run.isArchived {
                    Button {
                        store.open(run)
                    } label: {
                        Label("继续带团", systemImage: "play.fill")
                    }
                }
                Menu {
                    Button {
                        renameText = run.name
                        showRename = true
                    } label: {
                        Label("重命名…", systemImage: "pencil")
                    }
                    Button {
                        store.setArchived(!run.isArchived, in: run)
                    } label: {
                        Label(run.isArchived ? "恢复开团" : "归档开团", systemImage: "archivebox")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDelete = true
                    } label: {
                        Label("删除开团…", systemImage: "trash")
                    }
                } label: {
                    Label("更多", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showPrep) {
            PrepChecklistView(run: run)
                .environment(store)
        }
        .alert("重命名开团", isPresented: $showRename) {
            TextField("开团名称", text: $renameText)
            Button("取消", role: .cancel) {}
            Button("保存") {
                store.rename(run, to: renameText)
            }
        }
        .alert("删除这个开团？", isPresented: $showDelete) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                store.delete(run)
            }
        } message: {
            Text("“\(run.name)”的队伍、便签、战斗和日志都会被删除，不能撤销。")
        }
    }

    private func noteColor(_ color: NoteColor) -> Color {
        switch color {
        case .yellow: .yellow
        case .pink: .pink
        case .blue: .blue
        case .green: .green
        }
    }
}

private struct NewRunSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("新建开团")
                .font(.title2.weight(.semibold))
            Text("新建记录完全空白；队伍、flags、战斗状态和便签都不会从旧团复制。")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("例如：周五团 · B 组", text: $name)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("创建空白开团") {
                    store.createRun(name: name)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
