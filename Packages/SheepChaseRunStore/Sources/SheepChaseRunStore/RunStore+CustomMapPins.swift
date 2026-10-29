import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func customMapPins(for mapID: String, in run: RunRecord) -> [RunCustomMapPin] {
        run.customMapPins.filter { $0.mapID == mapID }
    }

    public func addCustomMapPin(
        mapID: String,
        x: Double,
        y: Double,
        label: String,
        note: String,
        in run: RunRecord
    ) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        run.customMapPins.append(
            RunCustomMapPin(
                mapID: mapID,
                x: min(max(x, 0), 1),
                y: min(max(y, 0), 1),
                label: trimmed,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        )
        commit(run)
    }

    public func deleteCustomMapPin(_ pinID: UUID, in run: RunRecord) {
        run.customMapPins.removeAll { $0.id == pinID }
        commit(run)
    }
}
