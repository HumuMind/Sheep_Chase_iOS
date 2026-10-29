import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func customBeats(for sceneID: String, in run: RunRecord) -> [RunCustomBeat] {
        run.customBeats.filter { $0.sceneID == sceneID }
    }

    public func addCustomBeat(
        sceneID: String,
        title: String,
        type: String,
        text: String,
        readAloud: String?,
        in run: RunRecord
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedText.isEmpty else { return }
        let note = readAloud?.trimmingCharacters(in: .whitespacesAndNewlines)
        run.customBeats.append(
            RunCustomBeat(
                sceneID: sceneID,
                title: trimmedTitle,
                type: type,
                text: trimmedText,
                readAloud: note?.isEmpty == true ? nil : note
            )
        )
        commit(run)
    }

    public func deleteCustomBeat(_ beatID: UUID, in run: RunRecord) {
        run.customBeats.removeAll { $0.id == beatID }
        if run.beatID == beatID.uuidString {
            run.beatID = ""
        }
        commit(run)
    }

    public func selectBeatID(_ beatID: String, in run: RunRecord) {
        run.beatID = beatID
        commit(run)
    }
}
