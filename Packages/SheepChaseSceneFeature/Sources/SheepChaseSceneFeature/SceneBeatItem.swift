import SheepChaseCore

struct SceneBeatItem: Identifiable {
    let id: String
    let title: String
    let type: String
    let text: String
    let readAloud: String?
    let content: ContentPack.Beat?
    let custom: RunCustomBeat?

    init(content: ContentPack.Beat) {
        self.id = content.id
        self.title = content.title
        self.type = content.type
        self.text = content.text
        self.readAloud = content.readAloud
        self.content = content
        self.custom = nil
    }

    init(custom: RunCustomBeat) {
        self.id = custom.id.uuidString
        self.title = custom.title
        self.type = custom.type
        self.text = custom.text
        self.readAloud = custom.readAloud
        self.content = nil
        self.custom = custom
    }
}
