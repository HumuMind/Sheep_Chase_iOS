import Foundation
import SwiftData
import XCTest
import SheepChaseCore
import SheepChasePersistence
@testable import SheepChaseRunStore

final class RunStoreTests: XCTestCase {
    private var content: ContentPack {
        get throws {
            var root = URL(fileURLWithPath: #filePath)
            for _ in 0..<5 { root.deleteLastPathComponent() }
            let url = root.appendingPathComponent("SheepChase/Resources/ContentPack.json")
            return try JSONDecoder().decode(ContentPack.self, from: Data(contentsOf: url))
        }
    }

    @MainActor
    func testStoreSeedsAndCreatesRuns() throws {
        let content = try content
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: config)
        let repository = RunRepository(context: container.mainContext)
        let seedRun = RunRecord(name: "种子团", contentVersion: content.manifest.version)
        let store = RunStore(
            repository: repository,
            content: content,
            appVersion: "test",
            backupDirectory: FileManager.default.temporaryDirectory,
            seed: { [seedRun] }
        )

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

        store.setAnnotation(kind: .scene, targetID: "scene-3", mode: .replace, text: "我把树屋改成了夜间场景。", in: run)
        XCTAssertEqual(store.annotation(kind: .scene, targetID: "scene-3", in: run)?.text, "我把树屋改成了夜间场景。")
        XCTAssertEqual(store.annotation(kind: .scene, targetID: "scene-3", in: run)?.mode, .replace)
        XCTAssertEqual(run.stateSnapshot.annotations?.first?.text, "我把树屋改成了夜间场景。")
        store.removeAnnotation(kind: .scene, targetID: "scene-3", in: run)
        XCTAssertNil(store.annotation(kind: .scene, targetID: "scene-3", in: run))

        store.addCustomBeat(sceneID: "scene-3", title: "自定义密道", type: "event", text: "队伍发现树屋下的密道。", readAloud: nil, in: run)
        XCTAssertEqual(store.customBeats(for: "scene-3", in: run).first?.title, "自定义密道")
        if let custom = store.customBeats(for: "scene-3", in: run).first {
            store.selectBeatID(custom.id.uuidString, in: run)
            XCTAssertEqual(run.beatID, custom.id.uuidString)
            store.deleteCustomBeat(custom.id, in: run)
        }
        XCTAssertTrue(store.customBeats(for: "scene-3", in: run).isEmpty)
    }
}
