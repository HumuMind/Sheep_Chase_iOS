import SwiftData
import XCTest
@testable import SheepChase

final class ContentAndExportTests: XCTestCase {
    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func loadContent() throws -> ContentPack {
        let url = repositoryRoot
            .appendingPathComponent("SheepChase/Resources/ContentPack.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ContentPack.self, from: data)
    }

    func testFullContentPackDecodes() throws {
        let content = try loadContent()
        XCTAssertEqual(content.scenes.count, 4)
        XCTAssertEqual(content.npcs.count, 3)
        XCTAssertEqual(content.monsters.count, 5)
        XCTAssertEqual(content.encounters.count, 3)
        XCTAssertEqual(content.rules.count, 22)
        XCTAssertEqual(content.spells.count, 14)
        XCTAssertEqual(content.assets.count, 3)
    }

    func testScenesAreCompleteAndOrdered() throws {
        let content = try loadContent()
        XCTAssertEqual(content.scenes.sorted { $0.order < $1.order }.map(\.id),
                       ["scene-1", "scene-2", "scene-3", "scene-4"])
        for scene in content.scenes {
            XCTAssertFalse(scene.beats.isEmpty, "\(scene.id) has no beats")
        }
    }

    func testRunExportRoundTrip() throws {
        let run = RunRecord(name: "导出测试团", contentVersion: "0.3.0")
        run.party = [
            PartyMember(name: "阿岚", role: "战士", level: 4, ac: 18, maxHP: 44, hp: 30, initMod: 1, passivePerception: 12)
        ]
        run.flags = ["scroll-used": true]
        run.stickyNotes = [StickyNote(text: "测试便签", color: .blue)]

        let data = try RunExport.data(for: run, contentVersion: "0.3.0")
        let snapshot = try RunExport.decoder().decode(RunSnapshot.self, from: data)
        XCTAssertEqual(snapshot.run.name, "导出测试团")
        XCTAssertEqual(snapshot.run.party.first?.name, "阿岚")
        XCTAssertEqual(snapshot.run.flags["scroll-used"], true)
        XCTAssertEqual(snapshot.run.notes.first?.text, "测试便签")
        XCTAssertEqual(snapshot.contentVersion, "0.3.0")
    }

    @MainActor
    func testImportCreatesANewRun() throws {
        let content = try loadContent()
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: configuration)
        let store = RunStore(context: container.mainContext, content: content)
        let countBefore = store.runs.count

        store.createRun(name: "导入测试团")
        guard let original = store.selectedRun else {
            return XCTFail("createRun should select the new run")
        }
        original.party = [
            PartyMember(name: "测试玩家", role: "战士", level: 4, ac: 16, maxHP: 30, hp: 30, initMod: 1, passivePerception: 11)
        ]
        let data = try store.exportJSON(for: original)
        let imported = try store.importRun(from: data)

        XCTAssertEqual(store.runs.count, countBefore + 2)
        XCTAssertEqual(imported.name, "导入测试团（导入）")
        XCTAssertEqual(imported.party.first?.name, "测试玩家")
        XCTAssertNotEqual(imported.id, original.id)
    }

    @MainActor
    func testArchiveRenameDeleteAndBattleUndo() throws {
        let content = try loadContent()
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: configuration)
        let store = RunStore(context: container.mainContext, content: content)

        store.createRun(name: "生命周期测试")
        guard let run = store.selectedRun else { return XCTFail("missing run") }
        store.rename(run, to: "改名后的团")
        XCTAssertEqual(run.name, "改名后的团")

        store.setArchived(true, in: run)
        XCTAssertTrue(run.isArchived)
        XCTAssertFalse(store.orderedRuns.contains { $0.id == run.id })
        XCTAssertTrue(store.archivedRuns.contains { $0.id == run.id })
        store.setArchived(false, in: run)

        store.addPlayer(to: run, name: "战士", role: "战士", level: 4, ac: 16, maxHP: 30, initMod: 1, passivePerception: 10)
        guard let member = run.party.first else { return XCTFail("missing party member") }
        store.openBattleSetup(for: run)
        store.toggleBattlePlayer(member, in: run)
        if let guz = content.monsters.first(where: { $0.id == "guz" }) {
            store.addBattleMonster(guz, in: run)
        }
        store.goToInitiative(in: run)
        store.setPlayerInitiative("15", memberID: member.id, in: run)
        store.startBattle(in: run)
        XCTAssertEqual(run.battle?.phase, .active)
        let hpBefore = store.activeCombatant(in: run)?.hp
        store.adjustHP(-5, in: run)
        XCTAssertEqual(store.activeCombatant(in: run)?.hp, (hpBefore ?? 0) - 5)
        store.undoBattle(in: run)
        XCTAssertEqual(store.activeCombatant(in: run)?.hp, hpBefore)

        let countBeforeDelete = store.runs.count
        store.delete(run)
        XCTAssertEqual(store.runs.count, countBeforeDelete - 1)
    }

    @MainActor
    func testSessionsAndCheckpoints() throws {
        let content = try loadContent()
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RunRecord.self, configurations: configuration)
        let store = RunStore(context: container.mainContext, content: content)
        store.createRun(name: "聚会测试")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        store.startSession(in: run)
        XCTAssertEqual(store.activeSession(in: run)?.endedAt, nil)
        store.endSession(note: "第一次聚会结束", in: run)
        XCTAssertEqual(store.activeSession(in: run), nil)
        XCTAssertEqual(run.sessions.count, 1)
        XCTAssertEqual(run.sessions.first?.note, "第一次聚会结束")
        XCTAssertFalse(run.checkpoints.isEmpty)

        store.createCheckpoint("手动测试", in: run)
        guard let checkpoint = run.checkpoints.first(where: { $0.label == "手动测试" }) else {
            return XCTFail("missing checkpoint")
        }
        store.restoreCheckpoint(checkpoint, in: run)
        XCTAssertEqual(run.sessions.count, 1)
    }

    func testFadeToBlackDescriptionsExist() throws {
        let content = try loadContent()
        for scene in content.scenes {
            XCTAssertNotNil(scene.fadeToBlack, "\(scene.id) should carry a safety fade description")
        }
    }

    func testMarkdownExportIncludesRunState() throws {
        let content = try loadContent()
        let run = RunRecord(name: "日志测试", sceneID: "scene-3", contentVersion: content.manifest.version)
        run.stickyNotes = [StickyNote(text: "记住诺克会逃跑", color: .pink)]
        let markdown = RunExport.markdown(for: run, content: content)
        XCTAssertTrue(markdown.contains("# 日志测试"))
        XCTAssertTrue(markdown.contains("场景三：林中小屋"))
        XCTAssertTrue(markdown.contains("记住诺克会逃跑"))
    }
}
