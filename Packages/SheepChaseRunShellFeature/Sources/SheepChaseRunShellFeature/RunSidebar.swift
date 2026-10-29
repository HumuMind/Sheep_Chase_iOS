import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

struct RunSidebar: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord
    @Binding var showGuide: Bool
    @State private var showSaveTemplate = false

    private var sceneSelection: Binding<String?> {
        Binding(
            get: { run.sceneID },
            set: { newValue in
                guard let newValue, let scene = store.scene(id: newValue) else { return }
                store.selectScene(scene, in: run)
            }
        )
    }

    var body: some View {
        List(selection: sceneSelection) {
            Section {
                Button {
                    showGuide = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "book.closed")
                            .foregroundStyle(Theme.red)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("DM 导读")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("摘要 · 引钩 · 背景 · 主持建议")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("必读")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Theme.red)
                    }
                    .padding(.vertical, 3)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("dm-guide-sidebar")
            } header: {
                Text("开始之前")
            }

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
                Button {
                    showSaveTemplate = true
                } label: {
                    Label("另存为我的模组", systemImage: "square.and.arrow.down.on.square")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.red)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("save-as-template")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.clear)
        .bookPaperSurface()
        .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 280)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 9) {
                SheepChaseImages.cover
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
        .sheet(isPresented: $showSaveTemplate) {
            SaveTemplateSheet(run: run)
                .environment(store)
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-demoSaveTemplate") {
                showSaveTemplate = true
            }
            #endif
        }
    }
}
