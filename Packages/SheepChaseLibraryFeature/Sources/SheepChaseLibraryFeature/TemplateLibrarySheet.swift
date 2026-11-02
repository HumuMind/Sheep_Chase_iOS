import SheepChaseCore
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI
import UniformTypeIdentifiers

struct TemplateLibrarySheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var renaming: AdventureTemplate?
    @State private var renameText = ""
    @State private var deleting: AdventureTemplate?
    @State private var exportDocument = TemplateExportDocument()
    @State private var exportFilename = "我的模组.json"
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var importError: String?

    var body: some View {
        BookFormSheet(
            title: "我的模组",
            primaryTitle: "完成",
            onCancel: { dismiss() },
            onPrimary: { dismiss() }
        ) {
            HStack {
                Button {
                    showImporter = true
                } label: {
                    Label("导入模组文件…", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                Spacer()
            }

            if store.orderedTemplates.isEmpty {
                Text("还没有保存过自己的模组。进入开团后，在左侧“本团”里选择“另存为我的模组”。")
                    .bookSerif(13)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.orderedTemplates) { template in
                    BookFormSection(template.name) {
                        if !template.summary.isEmpty {
                            Text(template.summary)
                                .bookSerif(13)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        Text("基于 \(template.baseModuleTitle) · \(template.baseContentVersion) · \(template.changeCount) 处改动")
                            .bookSerif(11)
                            .foregroundStyle(.secondary)
                        HStack {
                            Button("重命名") {
                                renameText = template.name
                                renaming = template
                            }
                            .buttonStyle(.bordered)
                            Button("导出") {
                                exportDocument = TemplateExportDocument(template: template)
                                exportFilename = "\(template.name).json"
                                showExporter = true
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                            Button("删除", role: .destructive) {
                                deleting = template
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .alert("重命名模组", isPresented: Binding(
            get: { renaming != nil },
            set: { if !$0 { renaming = nil } }
        )) {
            TextField("模组名称", text: $renameText)
            Button("取消", role: .cancel) {}
            Button("保存") {
                if let renaming {
                    try? store.renameTemplate(renaming, to: renameText)
                }
                renaming = nil
            }
        }
        .alert("删除这个模组？", isPresented: Binding(
            get: { deleting != nil },
            set: { if !$0 { deleting = nil } }
        )) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let deleting { store.deleteTemplate(deleting) }
                deleting = nil
            }
        } message: {
            Text("已用这个模组创建的开团不会受影响。")
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFilename
        ) { result in
            if case .failure(let error) = result {
                importError = error.localizedDescription
            }
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
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let template: AdventureTemplate
                    if let file = try? decoder.decode(AdventureTemplateFile.self, from: data) {
                        template = file.template
                    } else {
                        template = try decoder.decode(AdventureTemplate.self, from: data)
                    }
                    _ = try store.importTemplate(template)
                } catch {
                    importError = error.localizedDescription
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
        .alert("模板文件错误", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好") { importError = nil }
        } message: {
            Text(importError ?? "未知错误")
        }
    }
}
