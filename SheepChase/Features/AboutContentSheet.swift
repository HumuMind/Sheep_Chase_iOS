import SwiftUI

struct AboutContentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let content: ContentPack

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        Image("Cover")
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
                            Text("内容版本 \(content.manifest.version) · schema \(content.manifest.schemaVersion) · \(content.manifest.locale)")
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
                }
                .padding(24)
                .frame(maxWidth: 660, alignment: .leading)
                .readingPage()
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(BookPaperBackground())
            .groupBoxStyle(BookGroupBoxStyle())
            .navigationTitle("关于内容包")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 560, minHeight: 460)
    }
}
