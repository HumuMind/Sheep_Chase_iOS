import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct NotesInspector: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("便签")
                    .font(.headline)
                Spacer()
                Text("\(run.stickyNotes.count) 张")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                store.addNote(to: run)
            } label: {
                Label("新建便签", systemImage: "plus")
                    .font(Theme.ui(11, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if run.stickyNotes.isEmpty {
                Text("还没有便签。\n把 NPC 秘密、临时裁定或下次继续的位置分开记。")
                    .font(Theme.ui(10))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(run.stickyNotes) { note in
                    StickyNoteCard(note: note, run: run)
                }
            }

            Text("只属于当前开团；每张便签独立保存。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }
}

private struct StickyNoteCard: View {
    @Environment(RunStore.self) private var store
    let note: StickyNote
    @Bindable var run: RunRecord

    private var binding: Binding<String> {
        Binding(
            get: {
                run.stickyNotes.first { $0.id == note.id }?.text ?? ""
            },
            set: { newValue in
                store.updateNote(note.id, text: newValue, in: run)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextEditor(text: binding)
                .font(Theme.serif(11.5))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .frame(minHeight: 64)
                .foregroundStyle(Theme.inkSoft)

            HStack(spacing: 5) {
                ForEach(NoteColor.allCases) { color in
                    Button {
                        store.setNoteColor(color, for: note.id, in: run)
                    } label: {
                        Circle()
                            .fill(colorColor(color))
                            .frame(width: 9, height: 9)
                            .overlay(
                                Circle().stroke(
                                    note.color == color ? Theme.ink.opacity(0.45) : Color.clear,
                                    lineWidth: 1.5
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text(note.updatedAt.shortRelative)
                    .font(Theme.ui(8))
                    .foregroundStyle(Theme.muted.opacity(0.7))

                Button {
                    store.deleteNote(note.id, from: run)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.muted.opacity(0.7))
            }
        }
        .padding(9)
        .background(noteColor(note.color))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(noteBorder(note.color), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
    }

    private func noteColor(_ color: NoteColor) -> Color {
        switch color {
        case .yellow: Color(red: 0.98, green: 0.93, blue: 0.76)
        case .pink: Color(red: 0.97, green: 0.87, blue: 0.85)
        case .blue: Color(red: 0.85, green: 0.92, blue: 0.95)
        case .green: Color(red: 0.88, green: 0.94, blue: 0.84)
        }
    }

    private func noteBorder(_ color: NoteColor) -> Color {
        switch color {
        case .yellow: Color(red: 0.86, green: 0.76, blue: 0.45)
        case .pink: Color(red: 0.85, green: 0.68, blue: 0.63)
        case .blue: Color(red: 0.65, green: 0.78, blue: 0.84)
        case .green: Color(red: 0.68, green: 0.80, blue: 0.60)
        }
    }

    private func colorColor(_ color: NoteColor) -> Color {
        switch color {
        case .yellow: Color(red: 0.93, green: 0.80, blue: 0.35)
        case .pink: Color(red: 0.88, green: 0.65, blue: 0.60)
        case .blue: Color(red: 0.55, green: 0.75, blue: 0.84)
        case .green: Color(red: 0.63, green: 0.78, blue: 0.52)
        }
    }
}
