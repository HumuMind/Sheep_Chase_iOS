import Foundation
import XCTest
@testable import SheepChase

final class LocalDataLayoutTests: XCTestCase {
    private var baseDirectory: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        baseDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("SheepChaseLayout-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let baseDirectory {
            try? fileManager.removeItem(at: baseDirectory)
        }
    }

    func testStoreURLIsInsideSheepChaseFolder() throws {
        let url = try LocalDataLayout.storeURL(in: baseDirectory)

        XCTAssertEqual(url.lastPathComponent, "SheepChase.store")
        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Data")
        XCTAssertEqual(url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent, "SheepChase")
        XCTAssertTrue(fileManager.fileExists(atPath: url.deletingLastPathComponent().path))
    }

    func testLegacyStoreIsMigratedOnce() throws {
        let legacyStore = baseDirectory.appendingPathComponent("default.store")
        let legacyWAL = baseDirectory.appendingPathComponent("default.store-wal")
        try Data("主库".utf8).write(to: legacyStore)
        try Data("日志".utf8).write(to: legacyWAL)

        let storeURL = try LocalDataLayout.storeURL(in: baseDirectory)

        XCTAssertFalse(fileManager.fileExists(atPath: legacyStore.path))
        XCTAssertFalse(fileManager.fileExists(atPath: legacyWAL.path))
        XCTAssertEqual(try Data(contentsOf: storeURL), Data("主库".utf8))
        XCTAssertEqual(try Data(contentsOf: URL(fileURLWithPath: storeURL.path + "-wal")), Data("日志".utf8))
    }

    func testExistingNewStoreIsNotOverwritten() throws {
        let storeURL = try LocalDataLayout.storeURL(in: baseDirectory)
        try Data("新数据".utf8).write(to: storeURL)
        let legacyStore = baseDirectory.appendingPathComponent("default.store")
        try Data("旧数据".utf8).write(to: legacyStore)

        let reopened = try LocalDataLayout.storeURL(in: baseDirectory)

        XCTAssertEqual(reopened, storeURL)
        XCTAssertEqual(try Data(contentsOf: storeURL), Data("新数据".utf8))
        // 旧文件保留，方便手动找回。
        XCTAssertTrue(fileManager.fileExists(atPath: legacyStore.path))
    }

    func testTemplatesAreMigratedIntoSheepChaseFolder() throws {
        let legacyTemplates = baseDirectory.appendingPathComponent("MyAdventureTemplates.json")
        try Data("[]".utf8).write(to: legacyTemplates)

        let templatesURL = try LocalDataLayout.templateURL(in: baseDirectory)

        XCTAssertEqual(templatesURL.lastPathComponent, "MyAdventureTemplates.json")
        XCTAssertEqual(templatesURL.deletingLastPathComponent().lastPathComponent, "SheepChase")
        XCTAssertFalse(fileManager.fileExists(atPath: legacyTemplates.path))
    }
}
