import XCTest
import SheepChaseCore
@testable import SheepChaseRunStore

final class RunStoreAnnotationTests: RunStoreTestCase {
    @MainActor
    func testAnnotationsReplaceAndRemove() throws {
        let store = try makeStore()
        store.createRun(name: "批注团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        store.setAnnotation(
            kind: .scene,
            targetID: "scene-3",
            mode: .replace,
            text: "我把树屋改成了夜间场景。",
            in: run
        )
        XCTAssertEqual(store.annotation(kind: .scene, targetID: "scene-3", in: run)?.text, "我把树屋改成了夜间场景。")
        XCTAssertEqual(store.annotation(kind: .scene, targetID: "scene-3", in: run)?.mode, .replace)
        XCTAssertEqual(run.stateSnapshot.annotations?.first?.text, "我把树屋改成了夜间场景。")

        store.removeAnnotation(kind: .scene, targetID: "scene-3", in: run)
        XCTAssertNil(store.annotation(kind: .scene, targetID: "scene-3", in: run))
    }

    @MainActor
    func testMultipleAnnotationsCanBeAddedAndEdited() throws {
        let store = try makeStore()
        store.createRun(name: "批注团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        let first = store.addAnnotation(kind: .beat, targetID: "beat-1", mode: .append, text: "第一条", in: run)
        let second = store.addAnnotation(kind: .beat, targetID: "beat-1", mode: .replace, text: "第二条", in: run)
        XCTAssertEqual(store.annotations(kind: .beat, targetID: "beat-1", in: run).count, 2)

        let firstID = try XCTUnwrap(first?.id)
        store.updateAnnotation(id: firstID, mode: .replace, text: "第一条改", in: run)
        XCTAssertEqual(store.annotations(kind: .beat, targetID: "beat-1", in: run).first?.text, "第一条改")

        if let second {
            store.removeAnnotation(id: second.id, in: run)
        }
        XCTAssertEqual(store.annotations(kind: .beat, targetID: "beat-1", in: run).count, 1)
    }
}
