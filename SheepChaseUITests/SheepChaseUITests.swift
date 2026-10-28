import XCTest

final class SheepChaseUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDemoRunOpensSceneWorkspace() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins"]
        app.launch()

        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["全局速查"].exists)
        XCTAssertTrue(app.buttons["聚会记录"].exists)
        XCTAssertTrue(app.buttons["安全工具"].exists)
    }

    func testAdventureGuideOpens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        app.buttons["dm-guide-scene-banner"].tap()
        XCTAssertTrue(app.staticTexts["如何使用本冒险"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["冒险引钩"].exists)
    }

    func testQuickReferencePinAndDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        let tag = app.buttons["qr-tag-npc:guz-npc"]
        XCTAssertTrue(tag.waitForExistence(timeout: 5))
        tag.press(forDuration: 1.2)

        let pinAction = app.buttons["钉住"]
        XCTAssertTrue(pinAction.waitForExistence(timeout: 5))
        pinAction.tap()

        XCTAssertTrue(app.staticTexts["已钉住"].waitForExistence(timeout: 5))
        let pinnedText = app.staticTexts["古兹"].firstMatch
        XCTAssertTrue(pinnedText.waitForExistence(timeout: 5))
        pinnedText.tap()
        XCTAssertTrue(app.staticTexts["古兹"].waitForExistence(timeout: 5))
    }

    func testHomeButtonReturnsToLibrary() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        app.buttons["主页"].tap()
        XCTAssertTrue(app.staticTexts["我的开团"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["开团详情"].exists)
    }

    func testHomeActionsAreExpanded() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["我的开团"].waitForExistence(timeout: 12))

        XCTAssertTrue(app.buttons["重命名"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["归档开团"].exists)
        XCTAssertTrue(app.buttons["删除开团"].exists)
    }

    func testGlobalSearchOpens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        app.buttons["全局速查"].tap()
        XCTAssertTrue(app.staticTexts["全局速查"].waitForExistence(timeout: 5))
    }
}
