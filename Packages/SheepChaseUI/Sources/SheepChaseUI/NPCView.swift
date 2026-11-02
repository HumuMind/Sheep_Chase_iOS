import SwiftUI
import SheepChaseCore

public struct NPCSheetView: View {
    @Environment(\.dismiss) private var dismiss
    let npc: ContentPack.NPC
    let annotation: DMAnnotation?
    let onAnnotationSave: ((String, DMAnnotationMode) -> Void)?
    let onAnnotationDelete: (() -> Void)?

    public init(
        npc: ContentPack.NPC,
        annotation: DMAnnotation? = nil,
        onAnnotationSave: ((String, DMAnnotationMode) -> Void)? = nil,
        onAnnotationDelete: (() -> Void)? = nil
    ) {
        self.npc = npc
        self.annotation = annotation
        self.onAnnotationSave = onAnnotationSave
        self.onAnnotationDelete = onAnnotationDelete
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(npc.name)
                        .bookSerif(30, weight: .semibold)
                        .foregroundStyle(Theme.red)
                        .padding(.bottom, 16)

                    if let sourceText = npc.sourceText, !sourceText.isEmpty {
                        ForEach(paragraphs(sourceText).indices, id: \.self) { index in
                            Text("　　\(paragraphs(sourceText)[index])")
                                .bookSerif(15)
                                .lineSpacing(7)
                                .foregroundStyle(Theme.ink)
                                .textSelection(.enabled)
                                .padding(.bottom, 8)
                        }
                    } else {
                        Text(npc.dmDescription)
                            .bookSerif(15)
                            .lineSpacing(7)
                            .foregroundStyle(Theme.ink)
                            .padding(.bottom, 8)
                    }

                    if let characteristics = npc.keyCharacteristics, !characteristics.isEmpty {
                        Text("关键特征")
                            .bookSerif(20, weight: .semibold)
                            .foregroundStyle(Theme.red)
                            .padding(.top, 18)
                            .padding(.bottom, 6)
                        ForEach(characteristics, id: \.self) { characteristic in
                            HStack(alignment: .firstTextBaseline, spacing: 7) {
                                Text("•")
                                    .foregroundStyle(Theme.red)
                                Text(characteristic)
                                    .bookSerif(15)
                                    .foregroundStyle(Theme.ink)
                            }
                            .padding(.bottom, 3)
                        }
                    }

                    if let onAnnotationSave, let onAnnotationDelete {
                        DMAnnotationEditor(
                            subject: npc.name,
                            annotation: annotation,
                            onSave: onAnnotationSave,
                            onDelete: onAnnotationDelete
                        )
                        .padding(.top, 18)
                    }

                    pageFooter
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 38)
                .frame(maxWidth: BookSheetMetrics.pageWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color(red: 0.99, green: 0.97, blue: 0.92).opacity(0.35))
            }
            .background(Theme.sheetBackground)
            .navigationTitle("角色")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
            }
        }
        .environment(\.colorScheme, .light)
        .tint(Theme.red)
        .dismissOnBackgroundClick { dismiss() }
        .frame(minWidth: BookSheetMetrics.minWidth, idealWidth: BookSheetMetrics.idealWidth, minHeight: BookSheetMetrics.minHeight, idealHeight: BookSheetMetrics.idealHeight)
    }

    private var pageFooter: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                if let sourceRef = npc.sourceRef {
                    Text(sourceRef)
                }
                Text("荒野逐羊 · 简体中文版")
            }
            .bookSerif(10)
            .foregroundStyle(Theme.inkSoft.opacity(0.75))
            Spacer()
        }
        .padding(.top, 28)
    }

    private func paragraphs(_ text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
