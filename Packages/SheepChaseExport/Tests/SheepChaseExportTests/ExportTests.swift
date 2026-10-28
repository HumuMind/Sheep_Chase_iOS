import Foundation
import XCTest
import SheepChaseCore
import SheepChasePersistence
@testable import SheepChaseExport

final class ExportTests: XCTestCase {
    func testJSONRoundTrip() throws {
        let run = RunRecord(name: "导出测试", sceneID: "scene-3", contentVersion: "0.3.0")
        run.party = [PartyMember(name: "阿岚", role: "战士", level: 4, ac: 18, maxHP: 44, hp: 31, initMod: 1, passivePerception: 12)]
        run.stickyNotes = [StickyNote(text: "测试便签")]

        let data = try RunExport.data(for: run, contentVersion: "0.3.0", appVersion: "0.1.0")
        let snapshot = try RunExport.decoder().decode(RunSnapshot.self, from: data)
        XCTAssertEqual(snapshot.appVersion, "0.1.0")
        XCTAssertEqual(snapshot.contentVersion, "0.3.0")
        XCTAssertEqual(snapshot.run.name, "导出测试")
        XCTAssertEqual(snapshot.run.party.first?.name, "阿岚")
    }

    func testSafeFilename() {
        let filename = RunExport.safeFilename("周五/团:A", suffix: "备份", extension: "json")
        XCTAssertEqual(filename, "周五_团_A_备份.json")
        XCTAssertEqual(RunExport.safeFilename("", suffix: "日志", extension: "md"), "荒野逐羊_日志.md")
    }

    func testBackupServiceWritesSnapshots() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("SheepChaseExportTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: base) }
        let suite = "SheepChaseExportTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let run = RunRecord(name: "备份测试", contentVersion: "0.3.0")
        let folder = try XCTUnwrap(RunBackupService.createIfNeeded(
            runs: [run],
            contentVersion: "0.3.0",
            appVersion: "0.1.0",
            baseDirectory: base,
            defaults: defaults
        ))

        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        XCTAssertTrue(files.contains { $0.hasSuffix(".json") })
        XCTAssertTrue(files.contains("说明.txt"))
        XCTAssertNil(RunBackupService.createIfNeeded(
            runs: [run],
            contentVersion: "0.3.0",
            appVersion: "0.1.0",
            baseDirectory: base,
            defaults: defaults
        ))
    }
}
