import SwiftData
import XCTest
import SheepChaseCore
@testable import SheepChasePersistence

final class PersistenceTests: XCTestCase {
    @MainActor
    func testRepositoryInsertFetchAndComputedState() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: configuration)
        let repository = RunRepository(context: container.mainContext)

        let run = RunRecord(name: "测试团", contentVersion: "0.3.0")
        run.party = [PartyMember(name: "阿岚", role: "战士", level: 4, ac: 18, maxHP: 44, hp: 40, initMod: 1, passivePerception: 12)]
        run.flags = ["scroll-used": true]
        run.stickyNotes = [StickyNote(text: "测试")]
        run.safety = SafetyState(restLog: ["休息"])
        repository.insert(run)
        repository.save()

        let fetched = repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.party.first?.name, "阿岚")
        XCTAssertEqual(fetched.first?.flags["scroll-used"], true)
        XCTAssertEqual(fetched.first?.stickyNotes.first?.text, "测试")
        XCTAssertEqual(fetched.first?.safety.restLog, ["休息"])
        XCTAssertEqual(fetched.first?.stateSnapshot.sceneID, "scene-1")
    }

    @MainActor
    func testRepositoryDelete() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: configuration)
        let repository = RunRepository(context: container.mainContext)
        let run = RunRecord(name: "待删除")
        repository.insert(run)
        repository.save()
        repository.delete(run)
        repository.save()
        XCTAssertTrue(repository.fetchAll().isEmpty)
    }
}
