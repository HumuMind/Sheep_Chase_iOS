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
    }

    private var editorSheet: some View {
        NavigationStack {
            Form {
                Section("显示方式") {
                    Picker("显示方式", selection: $draftMode) {
                        ForEach(DMAnnotationMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("DM 内容") {
                    TextEditor(text: $draft)
                        .font(.body)
                        .frame(minHeight: 160)
                        .overlay(alignment: .topLeading) {
                            if draft.isEmpty {
                                Text("写下这个版本里改了什么、为什么改，或你希望怎么演……")
                                    .font(.callout)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .navigationTitle("DM 批注 · \(subject)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showEditor = false }
                }
                if annotation != nil {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("删除批注", role: .destructive) {
                            onDelete()
                            showEditor = false
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(draft, draftMode)
                        showEditor = false
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(minWidth: 480, minHeight: 380)
    }

    private func beginEditing() {
        draft = annotation?.text ?? ""
        draftMode = annotation?.mode ?? .append
        showEditor = true
    }
}
