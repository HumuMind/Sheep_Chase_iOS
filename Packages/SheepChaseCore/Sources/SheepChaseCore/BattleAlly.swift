import Foundation

public struct BattleAlly: Identifiable, Codable, Hashable {
    public var id: UUID
    public var baseID: String
    public var name: String
    public var subtitle: String
    public var ac: Int
    public var hp: Int
    public var maxHP: Int
    public var initiativeModifier: Int
    public var initiative: Int?
    public var speed: Int
    public var strength: Int
    public var dexterity: Int
    public var constitution: Int
    public var intelligence: Int
    public var wisdom: Int
    public var charisma: Int
    public var skills: [String]
    public var passivePerception: Int
    public var languages: [String]
    public var actions: [String]

    public init(
        id: UUID = UUID(),
        baseID: String,
        name: String,
        subtitle: String = "",
        ac: Int,
        hp: Int,
        maxHP: Int,
        initiativeModifier: Int = 0,
        initiative: Int? = nil,
        speed: Int = 30,
        strength: Int = 10,
        dexterity: Int = 10,
        constitution: Int = 10,
        intelligence: Int = 10,
        wisdom: Int = 10,
        charisma: Int = 10,
        skills: [String] = [],
        passivePerception: Int = 10,
        languages: [String] = [],
        actions: [String] = []
    ) {
        self.id = id
        self.baseID = baseID
        self.name = name
        self.subtitle = subtitle
        self.ac = ac
        self.hp = hp
        self.maxHP = maxHP
        self.initiativeModifier = initiativeModifier
        self.initiative = initiative
        self.speed = speed
        self.strength = strength
        self.dexterity = dexterity
        self.constitution = constitution
        self.intelligence = intelligence
        self.wisdom = wisdom
        self.charisma = charisma
        self.skills = skills
        self.passivePerception = passivePerception
        self.languages = languages
        self.actions = actions
    }
}
