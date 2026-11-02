import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ImageExportView: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAsset: ContentPack.Asset?
    @State private var showExporter = false
    @State private var exportDocument: AssetExportDocument?
    @State private var exportContentType: UTType = .jpeg
    @State private var exportFilename = "荒野逐羊_图片.jpg"
    @State private var exportError: String?
    @State private var exportNotice: String?

    var body: some View {
        NavigationStack {
            List(store.assets) { asset in
                HStack(spacing: 12) {
                    assetPreview(asset)
                        .frame(width: 82, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Theme.line, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(assetName(asset))
                            .font(.body.weight(.medium))
                        Text(assetKind(asset))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let credit = asset.credit {
                            Text(credit)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    HStack(spacing: 6) {
                        Button("导出") {
                            prepareExport(asset)
                        }
                        .buttonStyle(.bordered)
                        Button {
                            if let url = ContentAssetFile.url(for: asset) {
                                share([url])
                            } else {
                                exportError = "找不到图片文件。"
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                        .help("分享原图")
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedAsset = asset
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.readingPaper)
            .listRowBackground(Color.clear)
            .environment(\.colorScheme, .light)
            .navigationTitle("模组图片")
            .macNavigationSubtitle("干净原图 · 不烧录 DM 标记")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        exportAllToDirectory()
                    } label: {
                        Label("导出全部", systemImage: "folder.badge.plus")
                    }
                    Button {
                        shareAll()
                    } label: {
                        Label("分享全部", systemImage: "square.and.arrow.up.on.square")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
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
        .alert("图片导出", isPresented: Binding(
            get: { exportNotice != nil },
            set: { if !$0 { exportNotice = nil } }
        )) {
            Button("好") { exportNotice = nil }
        } message: {
            Text(exportNotice ?? "")
        }
    }

    @ViewBuilder
    private func assetPreview(_ asset: ContentPack.Asset) -> some View {
        switch asset.id {
        case "cover": SheepChaseImages.cover.resizable().scaledToFill()
        case "map-treehouse": SheepChaseImages.map.resizable().scaledToFill()
        case "sheep-illustration": SheepChaseImages.sheep.resizable().scaledToFit().padding(6)
        default: Image(systemName: "photo").foregroundStyle(.secondary)
        }
    }

    private func assetName(_ asset: ContentPack.Asset) -> String {
        switch asset.id {
        case "cover": "封面"
        case "map-treehouse": "树屋宅院地图"
        case "sheep-illustration": "绵羊速写"
        default: asset.exportFilename
        }
    }

    private func assetKind(_ asset: ContentPack.Asset) -> String {
        switch asset.kind {
        case "map": "地图 · 干净原图"
        case "cover": "封面 · 干净原图"
        case "illustration": "插画 · 干净原图"
        case "handout": "手牌 · 干净原图"
        default: asset.kind
        }
    }

    private func exportAllToDirectory() {
        let urls = store.assets.compactMap { ContentAssetFile.url(for: $0) }
        guard !urls.isEmpty else {
            exportError = "找不到可导出的图片。"
            return
        }
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "导出到这里"
        panel.message = "选择保存全部模组图片的目录"
        guard panel.runModal() == .OK, let directory = panel.url else { return }
        do {
            for url in urls {
                try copyUnique(url, to: directory)
            }
            let credit = creditText()
            try credit.write(to: directory.appendingPathComponent("荒野逐羊_图片说明.txt"), atomically: true, encoding: .utf8)
            exportNotice = "已导出 \(urls.count) 张原图到所选目录。"
        } catch {
            exportError = error.localizedDescription
        }
        #else
        var items = urls
        if let creditURL = writeCreditFile() {
            items.append(creditURL)
        }
        presentExportPicker(for: items)
        #endif
    }

    private func creditText() -> String {
        var lines = ["《荒野逐羊》模组图片", ""]
        for asset in store.assets {
            lines.append("\(asset.exportFilename)")
            lines.append("  来源：\(asset.credit ?? "未注明")")
        }
        lines.append("")
        lines.append("仅供个人跑团使用。")
        return lines.joined(separator: "\n") + "\n"
    }

    private func writeCreditFile() -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("荒野逐羊_图片说明.txt")
        do {
            try creditText().write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    #if os(macOS)
    private func copyUnique(_ source: URL, to directory: URL) throws {
        let base = source.deletingPathExtension().lastPathComponent
        let ext = source.pathExtension
        var destination = directory.appendingPathComponent(source.lastPathComponent)
        var index = 2
        while FileManager.default.fileExists(atPath: destination.path) {
            destination = directory.appendingPathComponent("\(base) (\(index)).\(ext)")
            index += 1
        }
        try FileManager.default.copyItem(at: source, to: destination)
    }
    #else
    private func presentExportPicker(for urls: [URL]) {
        let picker = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            root.present(picker, animated: true)
        }
    }
    #endif

    private func prepareExport(_ asset: ContentPack.Asset) {
        guard let url = ContentAssetFile.url(for: asset), let data = try? Data(contentsOf: url) else {
            exportError = "找不到图片文件。"
            return
        }
        let ext = url.pathExtension.lowercased()
        exportContentType = ext == "png" ? .png : .jpeg
        exportDocument = AssetExportDocument(data: data)
        exportFilename = asset.exportFilename
        showExporter = true
    }

    private func shareAll() {
        let urls = store.assets.compactMap { ContentAssetFile.url(for: $0) }
        guard !urls.isEmpty else {
            exportError = "找不到可分享的图片。"
            return
        }
        share(urls)
    }

    private func share(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        #if os(macOS)
        let picker = NSSharingServicePicker(items: urls)
        if let view = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
        #else
        let controller = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            controller.popoverPresentationController?.sourceView = root.view
            root.present(controller, animated: true)
        }
        #endif
    }
}

struct AssetExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.jpeg, .png] }
    static var writableContentTypes: [UTType] { [.jpeg, .png] }

    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

enum ContentAssetFile {
    static func url(for asset: ContentPack.Asset) -> URL? {
        let filename = URL(fileURLWithPath: asset.path).lastPathComponent
        let name = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "ContentAssets")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }
}
