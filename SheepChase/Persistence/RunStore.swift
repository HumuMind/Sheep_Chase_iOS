import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RunStore {
    let content: ContentPack
    private let context: ModelContext

    private(set) var runs: [RunRecord] = []
    var selectedRunID: UUID?
    var selectedTab: InspectorTab = .party
    var toast: String?

    private var toastTask: Task<Void, Never>?

    init(context: ModelContext, content: ContentPack) {
        self.context = context
        self.content = content
        fetchRuns()
        if runs.isEmpty {
            seedRuns()
        }
    }

    var selectedRun: RunRecord? {
        guard let selectedRunID else { return nil }
        return runs.first { $0.id == selectedRunID }
    }

    var orderedRuns: [RunRecord] {
        runs.filter { !$0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var archivedRuns: [RunRecord] {
        runs.filter(\.isArchived).sorted { $0.updatedAt > $1.updatedAt }
    }

    var adventure: ContentPack.Adventure { content.adventure }
    var scenes: [ContentPack.AdventureScene] { content.scenes.sorted { $0.order < $1.order } }

    var orderedBattleMonsters: [ContentPack.Monster] {
        let order = ["guz": 0, "wolf-guard": 1, "brown-bear": 2, "noke": 3, "bed-dragon-wyrmling": 4]
        return content.monsters.sorted {
            (order[$0.id] ?? 99) < (order[$1.id] ?? 99)
        }
    }

    var npcs: [ContentPack.NPC] {
        content.npcs.sorted { $0.name < $1.name }
    }

    var items: [ContentPack.Item] {
        content.items.sorted { $0.name < $1.name }
    }

    var handouts: [ContentPack.Handout] {
        content.handouts.sorted { $0.title < $1.title }
    }

    var maps: [ContentPack.MapData] {
        content.maps.sorted { $0.title < $1.title }
    }

    var assets: [ContentPack.Asset] {
        content.assets.sorted { $0.id < $1.id }
    }

    func npc(id: String) -> ContentPack.NPC? {
        content.npcs.first { $0.id == id }
    }

    func item(id: String) -> ContentPack.Item? {
        content.items.first { $0.id == id }
    }

    func handout(id: String) -> ContentPack.Handout? {
        content.handouts.first { $0.id == id }
    }

    func map(id: String) -> ContentPack.MapData? {
        content.maps.first { $0.id == id }
    }

    func asset(id: String) -> ContentPack.Asset? {
        content.assets.first { $0.id == id }
    }

    func rule(id: String) -> ContentPack.RuleCard? {
        content.rules.first { $0.id == id }
    }

    func spell(id: String) -> ContentPack.SpellCard? {
        content.spells.first { $0.id == id }
    }

    func scene(id: String) -> ContentPack.AdventureScene? {
        content.scenes.first { $0.id == id }
    }

    func monster(id: String) -> ContentPack.Monster? {
        content.monsters.first { $0.id == id }
    }

    func encounter(id: String) -> ContentPack.Encounter? {
        content.encounters.first { $0.id == id }
    }

    func flagLabel(_ id: String) -> String {
        content.flags.first { $0.id == id }?.label ?? id
    }

    func currentScene(for run: RunRecord) -> ContentPack.AdventureScene {
        scene(id: run.sceneID) ?? scenes.first!
    }

    // MARK: - Navigation

    func open(_ run: RunRecord) {
        selectedRunID = run.id
        selectedTab = run.battle?.phase == .active || run.mode == .battle ? .battle : .party
        run.updatedAt = .now
        persist()
    }

    func closeRun() {
        selectedRunID = nil
        selectedTab = .party
    }

    func createRun(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let run = RunRecord(
            name: trimmed.isEmpty ? "未命名开团" : trimmed,
            sceneID: scenes.first?.id ?? "scene-1",
            beatID: scenes.first?.beats.first?.id ?? "",
            contentVersion: content.manifest.version
        )
        context.insert(run)
        runs.append(run)
        selectedRunID = run.id
        selectedTab = .party
        persist()
        notify("已创建空白开团")
    }

    func selectScene(_ scene: ContentPack.AdventureScene, in run: RunRecord) {
        run.sceneID = scene.id
        run.beatID = scene.beats.first?.id ?? ""
        run.mode = .scene
        selectedTab = .party
        commit(run)
    }

    func selectBeat(_ beat: ContentPack.Beat, in run: RunRecord) {
        run.beatID = beat.id
        run.mode = .scene
        commit(run)
    }

    func setMode(_ mode: RunMode, in run: RunRecord) {
        if mode == .battle, run.battle == nil {
            run.battle = BattleState()
        }
        run.mode = mode
        if mode == .battle {
            selectedTab = .battle
        } else if selectedTab == .battle {
            selectedTab = .party
        }
        commit(run)
    }

    func toggleFlag(_ id: String, in run: RunRecord) {
        var flags = run.flags
        flags[id] = !(flags[id] ?? false)
        run.flags = flags
        commit(run)
    }

    // MARK: - Party

    func addPlayer(
        to run: RunRecord,
        name: String,
        role: String,
        level: Int,
        ac: Int,
        maxHP: Int,
        initMod: Int,
        passivePerception: Int
    ) {
        let member = PartyMember(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "冒险者" : role,
            level: level,
            ac: ac,
            maxHP: maxHP,
            hp: maxHP,
            initMod: initMod,
            passivePerception: passivePerception
        )
        var party = run.party
        party.append(member)
        run.party = party
        commit(run)
        notify("已添加玩家：\(member.name)")
    }

    // MARK: - Notes

    func addNote(to run: RunRecord) {
        var notes = run.stickyNotes
        notes.insert(StickyNote(), at: 0)
        run.stickyNotes = notes
        commit(run)
    }

    func updateNote(_ noteID: UUID, text: String, in run: RunRecord) {
        var notes = run.stickyNotes
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[index].text = text
        notes[index].updatedAt = .now
        run.stickyNotes = notes
        commit(run)
    }

    func setNoteColor(_ color: NoteColor, for noteID: UUID, in run: RunRecord) {
        var notes = run.stickyNotes
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[index].color = color
        notes[index].updatedAt = .now
        run.stickyNotes = notes
        commit(run)
    }

    func deleteNote(_ noteID: UUID, from run: RunRecord) {
        run.stickyNotes = run.stickyNotes.filter { $0.id != noteID }
        commit(run)
        notify("便签已删除")
    }

    // MARK: - Battle

    func battleState(for run: RunRecord) -> BattleState? {
        run.battle
    }

    func openBattleSetup(for run: RunRecord) {
        if run.battle == nil {
            run.battle = BattleState()
        }
        run.mode = .battle
        selectedTab = .battle
        commit(run)
    }

    func toggleBattlePlayer(_ member: PartyMember, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        if let index = battle.selectedPlayerIDs.firstIndex(of: member.id) {
            battle.selectedPlayerIDs.remove(at: index)
            battle.playerInitiatives.removeValue(forKey: member.id.uuidString)
        } else {
            battle.selectedPlayerIDs.append(member.id)
        }
        run.battle = battle
        commit(run)
    }

    func addBattleMonster(_ monster: ContentPack.Monster, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        let count = battle.monsters.filter { $0.baseID == monster.id }.count + 1
        let name: String
        switch monster.id {
        case "wolf-guard": name = "狼 \(count)"
        case "brown-bear": name = count == 1 ? "棕熊" : "棕熊 \(count)"
        case "bed-dragon-wyrmling": name = count == 1 ? "床龙雏龙" : "床龙雏龙 \(count)"
        default: name = count == 1 ? monster.name : "\(monster.name) \(count)"
        }
        battle.monsters.append(BattleMonster(baseID: monster.id, name: name))
        run.battle = battle
        commit(run)
    }

    func removeBattleMonster(_ monsterID: UUID, in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .select else { return }
        battle.monsters.removeAll { $0.id == monsterID }
        run.battle = battle
        commit(run)
    }

    func clearBattleDraft(in run: RunRecord) {
        run.battle = BattleState()
        commit(run)
    }

    func goToInitiative(in run: RunRecord) {
        guard var battle = run.battle else { return }
        for index in battle.monsters.indices {
            if battle.monsters[index].initiative == nil {
                let monster = self.monster(id: battle.monsters[index].baseID)
                battle.monsters[index].initiative = d20() + (monster?.initiativeModifier ?? 0)
            }
        }
        battle.phase = .initiative
        run.battle = battle
        commit(run)
    }

    func backToSelect(in run: RunRecord) {
        guard var battle = run.battle else { return }
        battle.phase = .select
        run.battle = battle
        commit(run)
    }

    func setPlayerInitiative(_ text: String, memberID: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        let key = memberID.uuidString
        if let value = Int(text) {
            battle.playerInitiatives[key] = value
        } else {
            battle.playerInitiatives.removeValue(forKey: key)
        }
        run.battle = battle
        commit(run)
    }

    func battleReady(_ run: RunRecord) -> Bool {
        guard let battle = run.battle, battle.totalParticipants > 0 else { return false }
        guard battle.selectedPlayerIDs.allSatisfy({
            battle.playerInitiatives[$0.uuidString] != nil
        }) else { return false }
        return battle.monsters.allSatisfy { $0.initiative != nil }
    }

    func suggestedEncounter(for run: RunRecord) -> String {
        guard let battle = run.battle else { return "先选择参战玩家" }
        let players = run.party.filter { battle.selectedPlayerIDs.contains($0.id) }
        guard !players.isEmpty else { return "先选择参战玩家" }
        let averageLevel = Double(players.reduce(0) { $0 + $1.level }) / Double(players.count)
        var wolves = max(1, players.count - 1)
        if averageLevel >= 5 { wolves += 1 }
        let bear = players.count >= 4 ? 1 : 0
        return "古兹 ×1 · 狼 ×\(wolves) · 棕熊 ×\(bear)（\(players.count) 人，平均 \(String(format: "%.1f", averageLevel)) 级）"
    }

    func startBattle(in run: RunRecord) {
        guard var battle = run.battle, battleReady(run) else { return }

        let selected = run.party.filter { battle.selectedPlayerIDs.contains($0.id) }
        var combatants: [BattleCombatant] = selected.compactMap { member in
            guard let initiative = battle.playerInitiatives[member.id.uuidString] else { return nil }
            return BattleCombatant(
                id: member.id,
                name: member.name,
                kind: .player,
                ac: member.ac,
                hp: member.hp,
                maxHP: member.maxHP,
                initiative: initiative,
                conditions: member.conditions
            )
        }

        for monsterState in battle.monsters {
            guard let stat = monster(id: monsterState.baseID), let initiative = monsterState.initiative else { continue }
            combatants.append(
                BattleCombatant(
                    id: monsterState.id,
                    name: monsterState.name,
                    kind: .monster,
                    ac: stat.ac.value,
                    hp: stat.hp.average,
                    maxHP: stat.hp.average,
                    initiative: initiative
                )
            )
        }

        combatants.sort {
            if $0.initiative == $1.initiative { return $0.name < $1.name }
            return $0.initiative > $1.initiative
        }
        guard let first = combatants.first else { return }

        battle.combatants = combatants
        battle.round = 1
        battle.activeID = first.id
        battle.phase = .active
        battle.log = [
            "先攻记录 → " + combatants.map { "\($0.name) \($0.initiative)" }.joined(separator: " · "),
            "第 1 轮 · \(first.name) 的回合",
        ]
        run.battle = battle
        run.mode = .battle
        selectedTab = .battle
        commit(run)
        createCheckpoint("进入战斗", in: run)
        notify("先攻已记录，进入第 1 轮")
    }

    func nextTurn(in run: RunRecord) {
        guard var battle = run.battle, battle.phase == .active else { return }
        guard let index = battle.combatants.firstIndex(where: { $0.id == battle.activeID }) else { return }
        battle.undo = undoSnapshot(battle)
        let next = (index + 1) % battle.combatants.count
        if next == 0 { battle.round += 1 }
        battle.activeID = battle.combatants[next].id
        battle.log.insert("第 \(battle.round) 轮 · \(battle.combatants[next].name) 的回合", at: 0)
        run.battle = battle
        commit(run)
    }

    func adjustHP(_ delta: Int, in run: RunRecord) {
        guard let activeID = run.battle?.activeID else { return }
        adjustHP(forID: activeID, delta: delta, in: run)
    }

    func adjustHP(forID id: UUID, delta: Int, in run: RunRecord) {
        guard var battle = run.battle,
              let index = battle.combatants.firstIndex(where: { $0.id == id })
        else { return }
        battle.undo = undoSnapshot(battle)
        let before = battle.combatants[index].hp
        battle.combatants[index].hp = min(
            battle.combatants[index].maxHP,
            max(0, battle.combatants[index].hp + delta)
        )
        if battle.combatants[index].hp == 0,
           !battle.combatants[index].conditions.contains("倒地") {
            battle.combatants[index].conditions.append("倒地")
        }
        battle.log.insert(
            "第 \(battle.round) 轮 · \(battle.combatants[index].name) \(delta > 0 ? "+" : "")\(delta) HP（\(before) → \(battle.combatants[index].hp)）",
            at: 0
        )
        if delta < 0, let concentration = battle.combatants[index].concentration, !concentration.isEmpty {
            let dc = max(10, (-delta) / 2)
            battle.log.insert("专注检定：\(battle.combatants[index].name) 维持「\(concentration)」需通过 DC \(dc) 体质豁免", at: 0)
        }
        if battle.combatants[index].hp == 0, battle.combatants[index].concentration != nil {
            battle.combatants[index].concentration = nil
            battle.log.insert("\(battle.combatants[index].name) 的专注中断", at: 0)
        }
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    func toggleCondition(_ condition: String, in run: RunRecord) {
        guard var battle = run.battle,
              let activeID = battle.activeID,
              let index = battle.combatants.firstIndex(where: { $0.id == activeID })
        else { return }
        battle.undo = undoSnapshot(battle)
        if let existing = battle.combatants[index].conditions.firstIndex(of: condition) {
            battle.combatants[index].conditions.remove(at: existing)
            battle.log.insert("\(battle.combatants[index].name) 移除状态：\(condition)", at: 0)
        } else {
            battle.combatants[index].conditions.append(condition)
            battle.log.insert("\(battle.combatants[index].name) 获得状态：\(condition)", at: 0)
        }
        run.battle = battle
        syncParty(run)
        commit(run)
    }

    func setConcentration(_ text: String, forID id: UUID, in run: RunRecord) {
        guard var battle = run.battle,
              let index = battle.combatants.firstIndex(where: { $0.id == id })
        else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        battle.undo = undoSnapshot(battle)
        battle.combatants[index].concentration = trimmed.isEmpty ? nil : trimmed
        battle.log.insert(trimmed.isEmpty ? "\(battle.combatants[index].name) 结束专注" : "\(battle.combatants[index].name) 开始专注：\(trimmed)", at: 0)
        run.battle = battle
        commit(run)
    }

    func rollDice(sides: Int, count: Int = 1, modifier: Int = 0, in run: RunRecord) -> Int {
        let rolls = (0..<max(1, count)).map { _ in Int.random(in: 1...max(2, sides)) }
        let total = rolls.reduce(0, +) + modifier
        if var battle = run.battle {
            battle.undo = undoSnapshot(battle)
            let mod = modifier == 0 ? "" : (modifier > 0 ? "+\(modifier)" : "\(modifier)")
            let detail = count > 1 ? " [\(rolls.map(String.init).joined(separator: "、"))]" : ""
            battle.log.insert("骰子 · \(count)d\(sides)\(mod) = \(total)\(detail)", at: 0)
            run.battle = battle
            commit(run)
        }
        return total
    }

    func undoBattle(in run: RunRecord) {
        guard var battle = run.battle, let undo = battle.undo else { return }
        var restoredLog = undo.log
        restoredLog.insert("已撤销上一步", at: 0)
        battle.combatants = undo.combatants
        battle.round = undo.round
        battle.activeID = undo.activeID
        battle.log = restoredLog
        battle.undo = nil
        run.battle = battle
        syncParty(run)
        commit(run)
        notify("已撤销上一步")
    }

    private func undoSnapshot(_ battle: BattleState) -> BattleUndo {
        BattleUndo(combatants: battle.combatants, round: battle.round, activeID: battle.activeID, log: battle.log)
    }

    func selectCombatant(_ id: UUID, in run: RunRecord) {
        guard var battle = run.battle else { return }
        battle.activeID = id
        run.battle = battle
        commit(run)
    }

    func endBattle(in run: RunRecord) {
        syncParty(run)
        run.battle = nil
        run.mode = .scene
        selectedTab = .party
        commit(run)
        createCheckpoint("战斗结束", in: run)
        notify("战斗结束，HP 与状态已同步")
    }

    func activeCombatant(in run: RunRecord) -> BattleCombatant? {
        guard let battle = run.battle, let activeID = battle.activeID else { return nil }
        return battle.combatants.first { $0.id == activeID }
    }

    // MARK: - Sessions, checkpoints, run management and safety

    func activeSession(in run: RunRecord) -> RunSession? {
        run.sessions.last { $0.endedAt == nil }
    }

    func startSession(in run: RunRecord) {
        guard activeSession(in: run) == nil else {
            notify("本次聚会已经开始")
            return
        }
        var sessions = run.sessions
        sessions.append(RunSession(startedAt: .now))
        run.sessions = sessions
        commit(run)
        createCheckpoint("开始聚会", in: run)
        notify("开始第 \(sessions.count) 次聚会")
    }

    func endSession(note: String, in run: RunRecord) {
        guard var session = activeSession(in: run) else { return }
        session.endedAt = .now
        session.note = note
        var sessions = run.sessions
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        }
        run.sessions = sessions
        commit(run)
        createCheckpoint("结束聚会", in: run)
        notify("聚会记录已保存")
    }

    func updateSessionNote(_ note: String, sessionID: UUID, in run: RunRecord) {
        var sessions = run.sessions
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].note = note
        run.sessions = sessions
        commit(run)
    }

    func createCheckpoint(_ label: String, in run: RunRecord) {
        var checkpoints = run.checkpoints
        checkpoints.insert(RunCheckpoint(label: label, state: run.stateSnapshot), at: 0)
        run.checkpoints = Array(checkpoints.prefix(12))
        commit(run)
    }

    func restoreCheckpoint(_ checkpoint: RunCheckpoint, in run: RunRecord) {
        run.apply(checkpoint.state)
        run.updatedAt = .now
        commit(run)
        notify("已恢复到「\(checkpoint.label)」")
    }

    func updateSafety(_ safety: SafetyState, in run: RunRecord) {
        run.safety = safety
        commit(run)
    }

    func recordRest(note: String, in run: RunRecord) {
        var safety = run.safety
        var log = safety.restLog ?? []
        let timestamp = Date().formatted(date: .abbreviated, time: .shortened)
        log.append("\(timestamp)　\(note.isEmpty ? "暂停 / 休息" : note)")
        safety.restLog = Array(log.suffix(20))
        run.safety = safety
        commit(run)
        notify("已记录休息")
    }

    func rename(_ run: RunRecord, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        run.name = trimmed
        commit(run)
        notify("开团已重命名")
    }

    func setArchived(_ archived: Bool, in run: RunRecord) {
        run.isArchived = archived
        if archived, selectedRunID == run.id {
            selectedRunID = nil
        }
        commit(run)
        notify(archived ? "已归档开团" : "已恢复开团")
    }

    func delete(_ run: RunRecord) {
        if selectedRunID == run.id { selectedRunID = nil }
        runs.removeAll { $0.id == run.id }
        context.delete(run)
        persist()
        notify("开团已删除")
    }

    func exportJSON(for run: RunRecord) throws -> Data {
        try RunExport.data(for: run, contentVersion: content.manifest.version)
    }

    func exportMarkdown(for run: RunRecord) -> String {
        RunExport.markdown(for: run, content: content)
    }

    func importRun(from data: Data) throws -> RunRecord {
        let snapshot = try RunExport.decoder().decode(RunSnapshot.self, from: data)
        let payload = snapshot.run
        let sceneID = scene(id: payload.sceneID) != nil ? payload.sceneID : (scenes.first?.id ?? "scene-1")
        let run = RunRecord(
            name: payload.name.isEmpty ? "导入开团" : "\(payload.name)（导入）",
            sceneID: sceneID,
            beatID: payload.beatID,
            contentVersion: content.manifest.version
        )
        run.apply(payload)
        run.contentVersion = content.manifest.version
        if !run.name.hasSuffix("（导入）") {
            run.name = "\(run.name)（导入）"
        }
        run.updatedAt = .now
        context.insert(run)
        runs.append(run)
        selectedRunID = run.id
        persist()
        notify("已导入为新开团")
        return run
    }

    // MARK: - Persistence

    private func syncParty(_ run: RunRecord) {
        guard let battle = run.battle else { return }
        var party = run.party
        for index in party.indices {
            guard let combatant = battle.combatants.first(where: { $0.id == party[index].id }) else { continue }
            party[index].hp = combatant.hp
            party[index].conditions = combatant.conditions
        }
        run.party = party
    }

    private func commit(_ run: RunRecord) {
        run.updatedAt = .now
        try? context.save()
    }

    private func persist() {
        try? context.save()
    }

    private func d20() -> Int {
        Int.random(in: 1...20)
    }

    func notify(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }

    // MARK: - Seed

    private func fetchRuns() {
        let descriptor = FetchDescriptor<RunRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        runs = (try? context.fetch(descriptor)) ?? []
    }

    private func seedRuns() {
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

        [friday, sunday, solo].forEach { context.insert($0) }
        persist()
        fetchRuns()
    }
}
