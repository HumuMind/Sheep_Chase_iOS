import SheepChaseSearchFeature
import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct NewRunSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedTemplateID: UUID?

    private var selectedTemplate: AdventureTemplate? {
        store.template(id: selectedTemplateID)
    }

    var body: some View {
        BookFormSheet(
            title: "新建开团",
            primaryTitle: "创建开团",
            primaryDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            onCancel: { dismiss() },
            onPrimary: create
        ) {
            BookFormSection("开团名称") {
                BookTextField("例如：周五团 · B 组", text: $name)
            }

            BookFormSection("选择模组") {
                moduleRow(
                    title: "原始模组",
                    subtitle: "\(store.content.manifest.title) · \(store.content.manifest.version)",
                    selected: selectedTemplateID == nil
                ) {
                    selectedTemplateID = nil
                }

                ForEach(store.orderedTemplates) { template in
                    moduleRow(
                        title: template.name,
                        subtitle: "基于 \(template.baseContentVersion) · \(template.changeCount) 处改动\(template.summary.isEmpty ? "" : " · \(template.summary)")",
                        selected: selectedTemplateID == template.id
                    ) {
                        selectedTemplateID = template.id
                    }
                }

                if store.orderedTemplates.isEmpty {
                    Text("还没有保存过自己的模组。进入开团后，可在左侧“本团”里另存为我的模组。")
                        .bookSerif(11)
                        .foregroundStyle(.secondary)
                }
            }

            if let selectedTemplate, selectedTemplate.baseContentVersion != store.content.manifest.version {
                Text("这个模组基于 \(selectedTemplate.baseContentVersion)，当前内容包是 \(store.content.manifest.version)。部分改动可能无法匹配，但仍可创建。")
                    .bookSerif(11)
                    .foregroundStyle(Theme.red)
            }

            Text("新开团会复制所选模组的改动，但队伍、便签、战斗、会话和进度都是全新的。")
                .bookSerif(11)
                .foregroundStyle(.secondary)
        }
    }

    private func moduleRow(title: String, subtitle: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Theme.red : .secondary)
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .bookSerif(15, weight: .medium)
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .bookSerif(11)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(10)
            .background(selected ? Theme.red.opacity(0.07) : Theme.paperDeep.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selected ? Theme.red.opacity(0.35) : Theme.line.opacity(0.55), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func create() {
        store.createRun(name: name, from: selectedTemplate)
        dismiss()
    }
}
