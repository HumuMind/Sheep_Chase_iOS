import SheepChaseCore
import SheepChasePersistence
import SheepChaseUI
import Foundation

@MainActor
extension RunStore {
    // MARK: - Seed

    func fetchRuns() {
        runs = repository.fetchAll()
    }

    func seedRuns() {
        let friday = RunRecord(name: "周五团 · A 组", sceneID: "scene-2", beatID: "guz-arrives", contentVersion: content.manifest.version)
        friday.party = [
            PartyMember(name: "阿岚", role: "战士", level: 4, ac: 18, maxHP: 44, hp: 36, initMod: 1, passivePerception: 12),
            PartyMember(name: "米娅", role: "法师", level: 4, ac: 13, maxHP: 27, hp: 22, initMod: 3, passivePerception: 11),
            PartyMember(name: "老科", role: "牧师", level: 4, ac: 17, maxHP: 38, hp: 31, initMod: 0, passivePerception: 15),
            PartyMember(name: "小影", role: "游荡者", level: 4, ac: 15, maxHP: 33, hp: 26, initMod: 4, passivePerception: 16),
        ]
        friday.flags = ["scroll-used": true]
        friday.stickyNotes = [
            StickyNote(
                text: "上次停在古兹上门；队伍还没决定是否动手。",
                color: .yellow,
                createdAt: Date().addingTimeInterval(-72000),
                updatedAt: Date().addingTimeInterval(-72000)
            ),
            StickyNote(
                text: "如果玩家抓住古兹，可以让他说出塔楼口令。",
                color: .blue,
                createdAt: Date().addingTimeInterval(-10800),
                updatedAt: Date().addingTimeInterval(-10800)
            ),
        ]

        let sunday = RunRecord(name: "周日新手团", contentVersion: content.manifest.version)
        sunday.party = [
            PartyMember(name: "森", role: "圣武士", level: 4, ac: 18, maxHP: 40, hp: 40, initMod: 0, passivePerception: 11),
            PartyMember(name: "鹿鸣", role: "德鲁伊", level: 4, ac: 14, maxHP: 28, hp: 28, initMod: 2, passivePerception: 15),
            PartyMember(name: "卡莉", role: "吟游诗人", level: 4, ac: 14, maxHP: 24, hp: 24, initMod: 3, passivePerception: 10),
        ]
        sunday.stickyNotes = [
            StickyNote(
                text: "开场前过安全工具；确认玩家都带了 4 级角色。",
                color: .pink,
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: Date().addingTimeInterval(-172800)
            ),
        ]

        let solo = RunRecord(name: "单刷测试团", contentVersion: content.manifest.version)
        solo.party = [
            PartyMember(name: "测试", role: "战士", level: 4, ac: 18, maxHP: 44, hp: 30, initMod: 1, passivePerception: 10),
        ]
        solo.flags = ["scroll-used": true]
        solo.updatedAt = Date().addingTimeInterval(-259200)

        [friday, sunday, solo].forEach { repository.insert($0) }
        persist()
        fetchRuns()
    }
}
