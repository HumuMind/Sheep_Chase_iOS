import SwiftUI
import UniformTypeIdentifiers

struct ImageExportView: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedAsset: ContentPack.Asset?
    @State private var showExporter = false
    @State private var exportDocument: AssetExportDocument?
    @State private var exportContentType: UTType = .jpeg
    @State private var exportFilename = "荒野逐羊_图片.jpg"
    @State private var exportError: String?

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
            .navigationTitle("模组图片")
            .macNavigationSubtitle("干净原图 · 不烧录 DM 标记")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
        .frame(minWidth: 600, minHeight: 440)
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
    }

    @ViewBuilder
    private func assetPreview(_ asset: ContentPack.Asset) -> some View {
        switch asset.id {
        case "cover": Image("Cover").resizable().scaledToFill()
        case "map-treehouse": Image("Map").resizable().scaledToFill()
        case "sheep-illustration": Image("Sheep").resizable().scaledToFit().padding(6)
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
