import XCTest

final class SheepChaseUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDemoRunOpensSceneWorkspace() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3"]
        app.launch()

        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["全局速查"].exists)
        XCTAssertTrue(app.buttons["聚会记录"].exists)
        XCTAssertTrue(app.buttons["安全工具"].exists)
    }

    func testAdventureGuideOpens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        app.buttons["dm-guide-scene-banner"].tap()
        XCTAssertTrue(app.staticTexts["如何使用本冒险"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["冒险引钩"].exists)
    }

    func testQuickReferencePinAndDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        let tag = app.buttons["qr-tag-npc:guz-npc"]
        XCTAssertTrue(tag.waitForExistence(timeout: 5))
        tag.press(forDuration: 1.2)

        let unpinAction = app.buttons["取消钉住"]
        if unpinAction.waitForExistence(timeout: 1) {
            unpinAction.tap()
            tag.press(forDuration: 1.2)
        }

        let pinAction = app.buttons["钉住"]
        XCTAssertTrue(pinAction.waitForExistence(timeout: 5))
        pinAction.tap()

        let pinned = app.buttons["qr-pinned-npc:guz-npc"]
        XCTAssertTrue(pinned.waitForExistence(timeout: 5))
        pinned.tap()
        XCTAssertTrue(app.staticTexts["古兹"].waitForExistence(timeout: 5))
    }

    func testGlobalSearchOpens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        app.buttons["全局速查"].tap()
        XCTAssertTrue(app.staticTexts["全局速查"].waitForExistence(timeout: 5))
    }
}
