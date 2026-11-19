import Foundation
import XCTest
import SheepChaseCore
import SheepChasePersistence
@testable import SheepChaseRunStore

final class RunStoreRunTests: RunStoreTestCase {
    @MainActor
    func testStoreSeedsAndCreatesRuns() throws {
        let content = try contentPack
        let seedRun = RunRecord(name: "种子团", contentVersion: content.manifest.version)
        let store = try makeStore(seed: { [seedRun] })

        XCTAssertEqual(store.runs.count, 1)
        XCTAssertEqual(store.runs.first?.name, "种子团")

        store.createRun(name: "新团")
        XCTAssertEqual(store.runs.count, 2)
        guard let run = store.selectedRun else { return XCTFail("missing run") }
        XCTAssertEqual(run.name, "新团")
        XCTAssertEqual(store.scenes.count, 4)

        store.selectScene(store.scenes[2], in: run)
        XCTAssertEqual(run.sceneID, "scene-3")
        store.addNote(to: run)
        XCTAssertEqual(run.stickyNotes.count, 1)
        store.setArchived(true, in: run)
        XCTAssertFalse(store.orderedRuns.contains { $0.id == run.id })

        store.togglePinnedReference("npc:finethir-shinebright", in: run)
        XCTAssertTrue(store.isPinnedReference("npc:finethir-shinebright", in: run))
        store.togglePinnedReference("npc:finethir-shinebright", in: run)
        XCTAssertFalse(store.isPinnedReference("npc:finethir-shinebright", in: run))
    }

    @MainActor
    func testMissingSceneFallsBackInsteadOfCrashing() throws {
        let store = try makeStore()
        store.createRun(name: "坏场景团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }
        run.sceneID = "does-not-exist"

        XCTAssertEqual(store.currentScene(for: run).id, store.scenes.first?.id)
    }
}
