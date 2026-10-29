import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func annotation(
        kind: DMAnnotationTargetKind,
        targetID: String,
        in run: RunRecord
    ) -> DMAnnotation? {
        run.annotations.first { $0.targetKind == kind && $0.targetID == targetID }
    }

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
        var annotations = run.annotations
        annotations.removeAll { $0.targetKind == kind && $0.targetID == targetID }
        run.annotations = annotations
        commit(run)
    }
}
