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

    func testSceneSourceTextOpens() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))

        let source = app.buttons["scene-source-button"]
        XCTAssertTrue(source.waitForExistence(timeout: 5))
        source.tap()
        XCTAssertTrue(app.buttons["完成"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Scene source sheet"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testScene2SourceShowsGuzStatBlock() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene2", "-demoSource", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景二：牧羊人与骗子"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["中型类人生物（半兽人），混乱中立"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["护甲等级 14（皮甲）"].exists)
        XCTAssertTrue(app.staticTexts["挑战等级 2（450 XP）"].exists)

        app.swipeUp()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Scene 2 Guz stat block"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testNPCCardUsesBookText() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoNPC", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["角色"].waitForExistence(timeout: 12))
        let intro = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "诺克是铁匠最小的孩子")
        ).firstMatch
        XCTAssertTrue(intro.waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "NPC character card"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testQuickReferencePinAndDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins", "-resetQuickReference"]
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

    func testQuickReferenceRemembersCollapsedState() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins", "-resetQuickReference"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))
        let collapse = app.buttons["收起速查"]
        XCTAssertTrue(collapse.waitForExistence(timeout: 5))
        collapse.tap()
        XCTAssertTrue(app.buttons["quick-reference-open"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["-demoRun", "-demoScene3", "-resetPins"]
        app.launch()
        XCTAssertTrue(app.staticTexts["场景三：林中小屋"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.buttons["quick-reference-open"].waitForExistence(timeout: 5))
        app.buttons["quick-reference-open"].tap()
        XCTAssertTrue(app.buttons["收起速查"].waitForExistence(timeout: 5))
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

        XCTAssertTrue(app.buttons["全局速查"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["DM 导读"].exists)
        XCTAssertTrue(app.buttons["新建开团"].exists)
        XCTAssertTrue(app.buttons["导入开团备份"].exists)
        XCTAssertTrue(app.buttons["关于内容包"].exists)
        XCTAssertTrue(app.buttons["重命名"].exists)
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
