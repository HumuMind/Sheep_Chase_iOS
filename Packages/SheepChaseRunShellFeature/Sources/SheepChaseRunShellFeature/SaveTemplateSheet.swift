import SwiftUI
import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI

struct SaveTemplateSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let run: RunRecord

    @State private var name: String
    @State private var summary = ""
    @State private var options = TemplateSaveOptions()
    @State private var errorMessage: String?
    @State private var saveMode: SaveMode = .new
    @State private var overwriteID: UUID?

    private enum SaveMode: String, CaseIterable {
        case new
        case overwrite
    }

    private var overwriteTemplate: AdventureTemplate? {
        store.template(id: overwriteID)
    }

    init(run: RunRecord) {
        self.run = run
        _name = State(initialValue: run.name)
    }

    var body: some View {
        BookFormSheet(
            title: "另存为我的模组",
            primaryTitle: saveMode == .overwrite ? "覆盖" : "保存",
            primaryDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || (saveMode == .overwrite && overwriteID == nil),
            onCancel: { dismiss() },
            onPrimary: save
        ) {
            BookFormSection("模组信息") {
                BookTextField("模组名称", text: $name)
                BookTextEditor("一句话简介（可选）", text: $summary, minHeight: 64)
                Text("\(store.content.manifest.title) · \(store.content.manifest.version)")
                    .font(Theme.serif(11))
                    .foregroundStyle(.secondary)
            }

            if !store.orderedTemplates.isEmpty {
                BookFormSection("保存方式") {
                    Picker("保存方式", selection: $saveMode) {
                        Text("新建模组").tag(SaveMode.new)
                        Text("覆盖已有模组").tag(SaveMode.overwrite)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()

                    if saveMode == .overwrite {
                        Picker("选择模组", selection: $overwriteID) {
                            Text("选择要覆盖的模组").tag(Optional<UUID>.none)
                            ForEach(store.orderedTemplates) { template in
                                Text(template.name).tag(Optional(template.id))
                            }
                        }
                        .pickerStyle(.menu)
                        Text("覆盖会更新模板内容，已经用旧模板创建的开团不受影响。")
                            .font(Theme.serif(11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            BookFormSection("保存内容") {
                toggle("DM 批注", detail: "\(run.annotations.count) 条", isOn: $options.includeAnnotations)
                toggle("自定义节拍 / NPC / 怪物", detail: "\(run.customBeats.count + run.customNPCs.count + run.customMonsters.count) 项", isOn: $options.includeCustomContent)
                toggle("遭遇与怪物数值调整", detail: "\(run.encounterAdjustments.count + run.monsterOverrides.count) 项", isOn: $options.includeEncounterAdjustments)
                toggle("自定义地图图钉", detail: "\(run.customMapPins.count) 个", isOn: $options.includeMapPins)
            }

            Text("只会保存模组内容改动，不会保存队伍、战斗、便签、会话记录、备团勾选或当前进度。")
                .font(Theme.serif(11))
                .foregroundStyle(.secondary)
        }
        .onChange(of: overwriteID) { _, newValue in
            if saveMode == .overwrite, let template = store.template(id: newValue) {
                name = template.name
                summary = template.summary
            }
        }
        .onChange(of: saveMode) { _, newValue in
            if newValue == .overwrite, let template = store.template(id: overwriteID) {
                name = template.name
                summary = template.summary
            }
        }
        .task {
            if overwriteID == nil {
                overwriteID = run.sourceTemplateID.flatMap { store.template(id: $0)?.id }
                    ?? store.orderedTemplates.first?.id
            }
        }
        .alert("保存失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private func toggle(_ title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack {
                Text(title)
                    .font(Theme.serif(13))
                Spacer()
                Text(detail)
                    .font(Theme.serif(11))
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
        .tint(Theme.red)
    }

    private func save() {
        do {
            if saveMode == .overwrite, let overwriteTemplate {
                _ = try store.overwriteTemplate(
                    overwriteTemplate,
                    from: run,
                    name: name,
                    summary: summary,
                    options: options
                )
            } else {
                _ = try store.saveRunAsTemplate(
                    from: run,
                    name: name,
                    summary: summary,
                    options: options
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
