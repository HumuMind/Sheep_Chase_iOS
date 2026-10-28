import SheepChaseSearchFeature
import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct LibraryRunDetail: View {
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
                    SheepChaseImages.cover
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

                GroupBox("冒险概览") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), alignment: .leading)], alignment: .leading, spacing: 8) {
                        overviewStat("\(store.scenes.count)", "场景")
                        overviewStat("\(store.npcs.count)", "NPC")
                        overviewStat("\(store.content.monsters.count)", "怪物")
                        overviewStat("\(store.content.encounters.count)", "遭遇")
                        overviewStat("\(store.handouts.count)", "手牌")
                        overviewStat("\(store.maps.count)", "地图")
                    }
                    .padding(.vertical, 3)
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

    private func overviewStat(_ value: String, _ label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.body.monospacedDigit().weight(.semibold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
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
