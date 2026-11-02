import SwiftUI
import SheepChaseCore

public struct DMAnnotationEditor: View {
    public init(
        subject: String,
        targetKind: DMAnnotationTargetKind,
        targetID: String,
        annotations: [DMAnnotation],
        onChange: @escaping ([DMAnnotation]) -> Void
    ) {
        self.subject = subject
        self.targetKind = targetKind
        self.targetID = targetID
        self.annotations = annotations
        self.onChange = onChange
    }

    private let subject: String
    private let targetKind: DMAnnotationTargetKind
    private let targetID: String
    private let annotations: [DMAnnotation]
    private let onChange: ([DMAnnotation]) -> Void

    @State private var showEditor = false
    @State private var editingID: UUID?
    @State private var draft = ""
    @State private var draftMode: DMAnnotationMode = .append

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(annotations) { annotation in
                annotationCard(annotation)
            }

            Button {
                beginAdding()
            } label: {
                Label(annotations.isEmpty ? "DM 注" : "＋ 添加 DM 注", systemImage: "square.and.pencil")
                    .bookUI(11)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Theme.gold)
            .help("添加仅本团可见的 DM 改动")
        }
        .sheet(isPresented: $showEditor) {
            editorSheet
        }
        .onAppear {
            #if DEBUG
            if subject == "朗读 / 描述", ProcessInfo.processInfo.arguments.contains("-demoAnnotation") {
                beginAdding()
            }
            #endif
        }
    }

    private func annotationCard(_ annotation: DMAnnotation) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Label("DM 改动", systemImage: "square.and.pencil")
                    .bookUI(11, weight: .semibold)
                    .foregroundStyle(Theme.gold)
                Text(annotation.mode.title)
                    .bookUI(10)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("编辑") { beginEditing(annotation) }
                    .bookUI(11)
                    .buttonStyle(.borderless)
                Button {
                    delete(annotation.id)
                } label: {
                    Image(systemName: "trash")
                        .bookUI(10)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("删除这条 DM 注")
            }
            Text(annotation.text)
                .bookUI(12)
                .foregroundStyle(Theme.inkSoft)
                .lineSpacing(3)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Theme.gold.opacity(0.08))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Theme.gold.opacity(0.75))
                .frame(width: 3)
        }
    }

    private var editorSheet: some View {
        BookFormSheet(
            title: editingID == nil ? "添加 DM 批注 · \(subject)" : "编辑 DM 批注 · \(subject)",
            primaryTitle: "保存",
            primaryDisabled: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            deleteTitle: editingID == nil ? nil : "删除",
            onCancel: { showEditor = false },
            onDelete: {
                if let editingID { delete(editingID) }
                showEditor = false
            },
            onPrimary: {
                saveDraft()
                showEditor = false
            }
        ) {
            BookFormSection("显示方式") {
                Picker("显示方式", selection: $draftMode) {
                    ForEach(DMAnnotationMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            BookFormSection("DM 内容") {
                BookTextEditor("写下这个版本里改了什么、为什么改，或你希望怎么演……", text: $draft, minHeight: 180)
            }
        }
    }

    private func beginAdding() {
        editingID = nil
        draft = ""
        draftMode = .append
        showEditor = true
    }

    private func beginEditing(_ annotation: DMAnnotation) {
        editingID = annotation.id
        draft = annotation.text
        draftMode = annotation.mode
        showEditor = true
    }

    private func saveDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var updated = annotations
        if let editingID, let index = updated.firstIndex(where: { $0.id == editingID }) {
            updated[index].text = trimmed
            updated[index].mode = draftMode
            updated[index].updatedAt = .now
        } else {
            updated.append(
                DMAnnotation(
                    targetKind: targetKind,
                    targetID: targetID,
                    mode: draftMode,
                    text: trimmed
                )
            )
        }
        onChange(updated)
    }

    private func delete(_ id: UUID) {
        onChange(annotations.filter { $0.id != id })
    }
}
