import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import SwiftUI

struct LibraryRunRow: View {
    @Environment(RunStore.self) private var store
    let run: RunRecord

    private var sceneIndex: Int {
        store.scenes.firstIndex { $0.id == run.sceneID } ?? 0
    }

    private var scene: ContentPack.AdventureScene? {
        store.scene(id: run.sceneID)
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 11))
                .foregroundStyle(Theme.red.opacity(0.8))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(scene?.title ?? "未知场景")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Text("\(sceneIndex + 1)/\(store.scenes.count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
