import SwiftUI
import SheepChaseCore

public struct DMAnnotationEditor: View {
    public init(
        subject: String,
        annotation: DMAnnotation?,
        onSave: @escaping (String, DMAnnotationMode) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.subject = subject
        self.annotation = annotation
        self.onSave = onSave
        self.onDelete = onDelete
        _draft = State(initialValue: annotation?.text ?? "")
        _draftMode = State(initialValue: annotation?.mode ?? .append)
    }

    private let subject: String
    private let annotation: DMAnnotation?
    private let onSave: (String, DMAnnotationMode) -> Void
    private let onDelete: () -> Void

    @State private var showEditor = false
    @State private var draft: String
    @State private var draftMode: DMAnnotationMode

    public var body: some View {
        Group {
            if let annotation, !annotation.text.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Label("DM 改动", systemImage: "square.and.pencil")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                        Text(annotation.mode.title)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("编辑") { beginEditing() }
                            .font(.caption)
                            .buttonStyle(.borderless)
                    }
                    Text(annotation.text)
                        .font(.callout)
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
            } else {
                Button {
                    beginEditing()
                } label: {
                    Label("DM 注", systemImage: "square.and.pencil")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Theme.gold)
                .help("添加仅本团可见的 DM 改动")
            }
        }
        .sheet(isPresented: $showEditor) {
            editorSheet
        }
        .onAppear {
            #if DEBUG
            if subject == "朗读 / 描述", ProcessInfo.processInfo.arguments.contains("-demoAnnotation") {
                beginEditing()
            }
            #endif
        }
    }

    private var editorSheet: some View {
        BookFormSheet(
            title: "DM 批注 · \(subject)",
            primaryTitle: "保存",
            primaryDisabled: draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            deleteTitle: annotation == nil ? nil : "删除",
            onCancel: { showEditor = false },
            onDelete: {
                onDelete()
                showEditor = false
            },
            onPrimary: {
                onSave(draft, draftMode)
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

    private func beginEditing() {
        draft = annotation?.text ?? ""
        draftMode = annotation?.mode ?? .append
        showEditor = true
    }
}
