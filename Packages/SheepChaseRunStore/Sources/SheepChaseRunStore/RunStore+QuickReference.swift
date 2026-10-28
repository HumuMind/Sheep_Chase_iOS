import Foundation
import SheepChasePersistence

@MainActor
extension RunStore {
    public func togglePinnedReference(_ id: String, in run: RunRecord) {
        var ids = run.pinnedReferenceIDs
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.append(id)
        }
        run.pinnedReferenceIDs = ids
        commit(run)
    }

    public func isPinnedReference(_ id: String, in run: RunRecord) -> Bool {
        run.pinnedReferenceIDs.contains(id)
    }
}
