import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func annotations(
        kind: DMAnnotationTargetKind,
        targetID: String,
        in run: RunRecord
    ) -> [DMAnnotation] {
        run.annotations.filter { $0.targetKind == kind && $0.targetID == targetID }
    }

    public func annotation(
        kind: DMAnnotationTargetKind,
        targetID: String,
        in run: RunRecord
    ) -> DMAnnotation? {
        annotations(kind: kind, targetID: targetID, in: run).first
    }

    @discardableResult
    public func addAnnotation(
        kind: DMAnnotationTargetKind,
        targetID: String,
        mode: DMAnnotationMode,
        text: String,
        in run: RunRecord
    ) -> DMAnnotation? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let annotation = DMAnnotation(
            targetKind: kind,
            targetID: targetID,
            mode: mode,
            text: trimmed,
            updatedAt: .now
        )
        run.annotations.append(annotation)
        commit(run)
        return annotation
    }

    public func updateAnnotation(
        id: UUID,
        mode: DMAnnotationMode,
        text: String,
        in run: RunRecord
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            removeAnnotation(id: id, in: run)
            return
        }
        guard let index = run.annotations.firstIndex(where: { $0.id == id }) else { return }
        run.annotations[index].mode = mode
        run.annotations[index].text = trimmed
        run.annotations[index].updatedAt = .now
        commit(run)
    }

    public func removeAnnotation(id: UUID, in run: RunRecord) {
        run.annotations.removeAll { $0.id == id }
        commit(run)
    }

    public func replaceAnnotations(
        kind: DMAnnotationTargetKind,
        targetID: String,
        with annotations: [DMAnnotation],
        in run: RunRecord
    ) {
        var all = run.annotations.filter { !($0.targetKind == kind && $0.targetID == targetID) }
        all.append(contentsOf: annotations)
        run.annotations = all
        commit(run)
    }

    // Backward-compatible single-annotation API.
    public func setAnnotation(
        kind: DMAnnotationTargetKind,
        targetID: String,
        mode: DMAnnotationMode,
        text: String,
        in run: RunRecord
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var annotations = run.annotations
        annotations.removeAll { $0.targetKind == kind && $0.targetID == targetID }
        if !trimmed.isEmpty {
            annotations.append(
                DMAnnotation(
                    targetKind: kind,
                    targetID: targetID,
                    mode: mode,
                    text: trimmed,
                    updatedAt: .now
                )
            )
        }
        run.annotations = annotations
        commit(run)
    }

    public func removeAnnotation(
        kind: DMAnnotationTargetKind,
        targetID: String,
        in run: RunRecord
    ) {
        run.annotations.removeAll { $0.targetKind == kind && $0.targetID == targetID }
        commit(run)
    }
}
