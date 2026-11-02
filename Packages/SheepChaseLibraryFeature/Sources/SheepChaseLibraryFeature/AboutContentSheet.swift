import SheepChaseSearchFeature
import SheepChaseRunStore
import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct AboutContentSheet: View {
    @Environment(RunStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let content: ContentPack
    @AppStorage("appTextSize") private var appTextSize = AppTextSize.large.rawValue
    @State private var showDeleteFirst = false
    @State private var showDeleteFinal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        SheepChaseImages.cover
                            .resizable()
                            .scaledToFill()
                            .frame(width: 86, height: 118)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Theme.line, lineWidth: 1)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(content.manifest.title)
                                .font(.largeTitle.weight(.semibold))
                            Text(content.manifest.originalTitle)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                            Text("App \(AppVersion.short) · 内容版本 \(content.manifest.version) · schema \(content.manifest.schemaVersion) · \(content.manifest.locale)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    GroupBox("署名") {
                        VStack(alignment: .leading, spacing: 7) {
                            ForEach(content.manifest.credits) { credit in
                                HStack(alignment: .firstTextBaseline) {
                                    Text(credit.name)
                                        .font(.callout.weight(.medium))
                                    Text(credit.role)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let url = credit.url, let link = URL(string: url) {
                                        Link("链接", destination: link)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 3)
                    }

                    GroupBox("界面字号") {
                        Picker("界面字号", selection: $appTextSize) {
                            ForEach(AppTextSize.allCases) { size in
                                Text(size.title).tag(size.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    GroupBox("版本与备份") {
                        Text("App \(AppVersion.short)（build \(AppVersion.build)）。启动新版本时，App 会自动把当前开团导出到本机 Application Support/SheepChase/Backups，保留最近 3 次；升级前也可以手动导出 JSON。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }

                    GroupBox("使用范围") {
                        Text("当前内容包标记为“个人自用”。冒险文本、中文翻译、封面插画与地图仅用于本地个人跑团，不用于公开分发；若要改变分发方式，需要重新评估授权与素材替换。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }

                    GroupBox("内容提示") {
                        Text(content.adventure.contentWarnings.joined(separator: " · "))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 3)
                    }

                    GroupBox("危险操作") {
                        Button(role: .destructive) {
                            showDeleteFirst = true
                        } label: {
                            Label("删除全部开团数据…", systemImage: "trash")
                        }
                        .buttonStyle(.borderless)
                        Text("会删除本机所有开团、队伍、便签、战斗记录和快照；不会删除内容包。建议先导出 JSON 备份。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 3)
                    }
                }
                .padding(24)
                .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Theme.sheetBackground)
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle("关于内容包")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
        .dismissOnBackgroundClick { dismiss() }
        .confirmationDialog("删除全部开团数据？", isPresented: $showDeleteFirst, titleVisibility: .visible) {
            Button("继续", role: .destructive) { showDeleteFinal = true }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作不可撤销。请确认已导出需要保留的 JSON 备份。")
        }
        .alert("最后确认", isPresented: $showDeleteFinal) {
            Button("取消", role: .cancel) {}
            Button("永久删除", role: .destructive) {
                store.deleteAllData()
                dismiss()
            }
        } message: {
            Text("真的删除本机全部开团数据吗？内容包和图片资源不会受影响。")
        }
    }
}
