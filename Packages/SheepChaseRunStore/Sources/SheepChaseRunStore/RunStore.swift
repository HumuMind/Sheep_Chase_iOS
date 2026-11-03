import SheepChaseBattleEngine
import SheepChaseExport
import SheepChaseCore
import SheepChasePersistence
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class RunStore {
    public let content: ContentPack
    public let repository: RunRepository
    public let appVersion: String
    public let backupDirectory: URL
    public let templateRepository: AdventureTemplateRepository

    public var runs: [RunRecord] = []
    public var templates: [AdventureTemplate] = []
    public var selectedRunID: UUID?
    public var selectedTab: InspectorTab = .party
    public var toast: String?
    public var diceSheetRequest: DiceSheetRequest?

    private var toastTask: Task<Void, Never>?

    public init(
        repository: RunRepository,
        content: ContentPack,
        appVersion: String,
        backupDirectory: URL,
        templateRepository: AdventureTemplateRepository? = nil,
        seed: () -> [RunRecord] = { [] }
    ) {
        self.repository = repository
        self.content = content
        self.appVersion = appVersion
        self.backupDirectory = backupDirectory
        self.templateRepository = templateRepository
            ?? AdventureTemplateRepository(fileURL: backupDirectory.appendingPathComponent("MyAdventureTemplates.json"))
        self.templates = self.templateRepository.load().sorted { $0.updatedAt > $1.updatedAt }
        fetchRuns()
        if runs.isEmpty {
            let demoRuns = seed()
            demoRuns.forEach { repository.insert($0) }
            repository.save()
            fetchRuns()
        }
    }

    public func fetchRuns() {
        runs = repository.fetchAll()
    }

    public var selectedRun: RunRecord? {
        guard let selectedRunID else { return nil }
        return runs.first { $0.id == selectedRunID }
    }

    public var orderedRuns: [RunRecord] {
        runs.filter { !$0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    public var archivedRuns: [RunRecord] {
        runs.filter(\.isArchived).sorted { $0.updatedAt > $1.updatedAt }
    }

    public var adventure: ContentPack.Adventure { content.adventure }
    public var scenes: [ContentPack.AdventureScene] { content.scenes.sorted { $0.order < $1.order } }

    public var orderedBattleMonsters: [ContentPack.Monster] {
        let order = ["guz": 0, "wolf-guard": 1, "brown-bear": 2, "noke": 3, "bed-dragon-wyrmling": 4]
        return content.monsters.sorted {
            (order[$0.id] ?? 99) < (order[$1.id] ?? 99)
        }
    }

    public var npcs: [ContentPack.NPC] {
        content.npcs.sorted { $0.name < $1.name }
    }

    public var items: [ContentPack.Item] {
        content.items.sorted { $0.name < $1.name }
    }

    public var handouts: [ContentPack.Handout] {
        content.handouts.sorted { $0.title < $1.title }
    }

    public var maps: [ContentPack.MapData] {
        content.maps.sorted { $0.title < $1.title }
    }

    public var assets: [ContentPack.Asset] {
        content.assets.sorted { $0.id < $1.id }
    }

    public func npc(id: String) -> ContentPack.NPC? {
        content.npcs.first { $0.id == id }
    }

    public func item(id: String) -> ContentPack.Item? {
        content.items.first { $0.id == id }
    }

    public func handout(id: String) -> ContentPack.Handout? {
        content.handouts.first { $0.id == id }
    }

    public func map(id: String) -> ContentPack.MapData? {
        content.maps.first { $0.id == id }
    }

    public func asset(id: String) -> ContentPack.Asset? {
        content.assets.first { $0.id == id }
    }

    public func rule(id: String) -> ContentPack.RuleCard? {
        content.rules.first { $0.id == id }
    }

    public func spell(id: String) -> ContentPack.SpellCard? {
        content.spells.first { $0.id == id }
    }

    public func scene(id: String) -> ContentPack.AdventureScene? {
        content.scenes.first { $0.id == id }
    }

    public func monster(id: String) -> ContentPack.Monster? {
        content.monsters.first { $0.id == id }
    }

    public func encounter(id: String) -> ContentPack.Encounter? {
        content.encounters.first { $0.id == id }
    }

    public func flagLabel(_ id: String) -> String {
        content.flags.first { $0.id == id }?.label ?? id
    }

    public func currentScene(for run: RunRecord) -> ContentPack.AdventureScene {
        scene(id: run.sceneID) ?? scenes.first!
    }

    // MARK: - Navigation

    public func open(_ run: RunRecord) {
        selectedRunID = run.id
        selectedTab = run.battle?.phase == .active || run.mode == .battle ? .battle : .party
        run.updatedAt = .now
        persist()
    }

    public func closeRun() {
        selectedRunID = nil
        selectedTab = .party
    }

    public func createRun(name: String) {
        createRun(name: name, from: nil)
    }

    public func selectScene(_ scene: ContentPack.AdventureScene, in run: RunRecord) {
        run.sceneID = scene.id
        run.beatID = scene.beats.first?.id ?? ""
        run.mode = .scene
        selectedTab = .party
        commit(run)
    }

    public func selectBeat(_ beat: ContentPack.Beat, in run: RunRecord) {
        run.beatID = beat.id
        run.mode = .scene
        commit(run)
    }

    public func setMode(_ mode: RunMode, in run: RunRecord) {
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

    public func toggleFlag(_ id: String, in run: RunRecord) {
        var flags = run.flags
        flags[id] = !(flags[id] ?? false)
        run.flags = flags
        commit(run)
    }

    // MARK: - Party

    public func addPlayer(
        to run: RunRecord,
        name: String,
        role: String,
        level: Int,
        ac: Int,
        maxHP: Int,
        initMod: Int,
        passivePerception: Int,
        currentHP: Int? = nil,
        tempHP: Int = 0
    ) {
        let member = PartyMember(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            role: role.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "冒险者" : role,
            level: level,
            ac: ac,
            maxHP: maxHP,
            hp: min(max(currentHP ?? maxHP, 1), maxHP),
            initMod: initMod,
            passivePerception: passivePerception,
            tempHP: max(tempHP, 0)
        )
        var party = run.party
        party.append(member)
        run.party = party
        commit(run)
        notify("已添加玩家：\(member.name)")
    }

    public func sceneNote(for sceneID: String, in run: RunRecord) -> String {
        run.sceneNotes[sceneID] ?? ""
    }

    public func updateSceneNote(_ text: String, sceneID: String, in run: RunRecord) {
        var notes = run.sceneNotes
        notes[sceneID] = text
        run.sceneNotes = notes
        commit(run)
    }

    public func isPrepChecked(_ id: String, in run: RunRecord) -> Bool {
        run.prepChecks.contains(id)
    }

    public func togglePrep(_ id: String, in run: RunRecord) {
        var checks = run.prepChecks
        if let index = checks.firstIndex(of: id) {
            checks.remove(at: index)
        } else {
            checks.append(id)
        }
        run.prepChecks = checks
        commit(run)
    }

    public func clearPrep(in run: RunRecord) {
        run.prepChecks = []
        commit(run)
    }

    public func updatePlayer(_ member: PartyMember, in run: RunRecord) {
        var party = run.party
        guard let index = party.firstIndex(where: { $0.id == member.id }) else { return }
        party[index] = member
        run.party = party
        if var battle = run.battle, let battleIndex = battle.combatants.firstIndex(where: { $0.id == member.id }) {
            battle.combatants[battleIndex].name = member.name
            battle.combatants[battleIndex].ac = member.ac
            battle.combatants[battleIndex].maxHP = member.maxHP
            battle.combatants[battleIndex].hp = min(member.hp, member.maxHP)
            battle.combatants[battleIndex].tempHP = member.tempHP
            battle.combatants[battleIndex].conditions = member.conditions
            run.battle = battle
        }
        commit(run)
        notify("玩家资料已更新")
    }

    public func removePlayer(_ member: PartyMember, from run: RunRecord) {
        if run.battle?.phase == .active {
            notify("战斗进行中，先结束战斗再移除玩家")
            return
        }
        run.party = run.party.filter { $0.id != member.id }
        if var battle = run.battle {
            battle.selectedPlayerIDs.removeAll { $0 == member.id }
            battle.playerInitiatives.removeValue(forKey: member.id.uuidString)
            battle.combatants.removeAll { $0.id == member.id }
            run.battle = battle
        }
        commit(run)
        notify("已移除玩家：\(member.name)")
    }

    // MARK: - Notes

    public func addNote(to run: RunRecord) {
        var notes = run.stickyNotes
        notes.insert(StickyNote(), at: 0)
        run.stickyNotes = notes
        commit(run)
    }

    public func updateNote(_ noteID: UUID, text: String, in run: RunRecord) {
        var notes = run.stickyNotes
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[index].text = text
        notes[index].updatedAt = .now
        run.stickyNotes = notes
        commit(run)
    }

    public func setNoteColor(_ color: NoteColor, for noteID: UUID, in run: RunRecord) {
        var notes = run.stickyNotes
        guard let index = notes.firstIndex(where: { $0.id == noteID }) else { return }
        notes[index].color = color
        notes[index].updatedAt = .now
        run.stickyNotes = notes
        commit(run)
    }

    public func deleteNote(_ noteID: UUID, from run: RunRecord) {
        run.stickyNotes = run.stickyNotes.filter { $0.id != noteID }
        commit(run)
        notify("便签已删除")
    }

// MARK: - Persistence

    public func syncParty(_ run: RunRecord) {
        guard let battle = run.battle else { return }
        var party = run.party
        for index in party.indices {
            guard let combatant = battle.combatants.first(where: { $0.id == party[index].id }) else { continue }
            party[index].hp = combatant.hp
            party[index].tempHP = combatant.tempHP
            party[index].conditions = combatant.conditions
        }
        run.party = party
    }

    public func commit(_ run: RunRecord) {
        run.updatedAt = .now
        repository.save()
    }

    public func persist() {
        repository.save()
    }

    public func d20() -> Int {
        Int.random(in: 1...20)
    }

    public func notify(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }
}
