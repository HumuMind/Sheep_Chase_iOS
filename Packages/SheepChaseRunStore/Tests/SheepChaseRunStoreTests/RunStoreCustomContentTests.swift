import XCTest
import SheepChaseCore
@testable import SheepChaseRunStore

final class RunStoreCustomContentTests: RunStoreTestCase {
    @MainActor
    func testCustomBeatLifecycle() throws {
        let store = try makeStore()
        store.createRun(name: "自定义团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        store.addCustomBeat(
            sceneID: "scene-3",
            title: "自定义密道",
            type: "event",
            text: "队伍发现树屋下的密道。",
            readAloud: nil,
            in: run
        )
        let custom = try XCTUnwrap(store.customBeats(for: "scene-3", in: run).first)
        XCTAssertEqual(custom.title, "自定义密道")

        store.selectBeatID(custom.id.uuidString, in: run)
        XCTAssertEqual(run.beatID, custom.id.uuidString)

        store.updateCustomBeat(
            custom.id,
            title: "密道入口",
            type: "decision",
            text: "队伍决定是否进入密道。",
            readAloud: nil,
            in: run
        )
        XCTAssertEqual(store.customBeats(for: "scene-3", in: run).first?.title, "密道入口")

        store.deleteCustomBeat(custom.id, in: run)
        XCTAssertTrue(store.customBeats(for: "scene-3", in: run).isEmpty)
    }

    @MainActor
    func testCustomNPCAndMonsterAreResolvableByID() throws {
        let store = try makeStore()
        store.createRun(name: "自定义团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        store.addCustomNPC(
            name: "自定义线人",
            role: "情报贩子",
            description: "知道树屋密道。",
            keyCharacteristics: ["谨慎"],
            in: run
        )
        let npc = try XCTUnwrap(store.customNPCs(in: run).first)
        XCTAssertEqual(store.npc(id: "custom-npc-\(npc.id.uuidString)", in: run)?.name, "自定义线人")

        store.addCustomMonster(
            name: "守门魔像",
            size: "大型",
            type: "构装体",
            alignment: "无阵营",
            ac: 17,
            hp: 60,
            initiativeModifier: -1,
            actionText: "挥拳攻击。",
            in: run
        )
        XCTAssertTrue(store.orderedBattleMonsters(in: run).contains { $0.name == "守门魔像" })
        let monster = try XCTUnwrap(store.customMonsters(in: run).first)
        XCTAssertEqual(store.monster(id: "custom-monster-\(monster.id.uuidString)", in: run)?.name, "守门魔像")
    }

    @MainActor
    func testCustomMapPinAndMonsterOverride() throws {
        let store = try makeStore()
        store.createRun(name: "自定义团")
        guard let run = store.selectedRun else { return XCTFail("missing run") }

        store.addCustomMapPin(mapID: "treehouse", x: 0.4, y: 0.6, label: "密道", note: "通往厨房", in: run)
        XCTAssertEqual(store.customMapPins(for: "treehouse", in: run).first?.label, "密道")

        store.setMonsterOverride(monsterID: "guz", ac: 18, hp: 80, initiativeModifier: 4, note: "强化版", in: run)
        XCTAssertEqual(store.monsterForBattle(id: "guz", in: run)?.ac.value, 18)
        XCTAssertEqual(store.monsterForBattle(id: "guz", in: run)?.hp.average, 80)
        XCTAssertEqual(store.monsterForBattle(id: "guz", in: run)?.initiativeModifier, 4)
    }
}
