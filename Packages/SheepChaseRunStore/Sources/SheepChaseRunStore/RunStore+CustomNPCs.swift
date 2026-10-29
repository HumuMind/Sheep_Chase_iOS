import Foundation
import SheepChaseCore
import SheepChasePersistence

@MainActor
extension RunStore {
    public func customNPCs(in run: RunRecord) -> [RunCustomNPC] {
        run.customNPCs.sorted { $0.createdAt < $1.createdAt }
    }

    public func addCustomNPC(
        name: String,
        role: String,
        description: String,
        keyCharacteristics: [String],
        in run: RunRecord
    ) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !description.isEmpty else { return }
        run.customNPCs.append(
            RunCustomNPC(
                name: name,
                role: role.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description,
                keyCharacteristics: keyCharacteristics
            )
        )
        commit(run)
    }

    public func deleteCustomNPC(_ id: UUID, in run: RunRecord) {
        let targetID = "custom-npc-\(id.uuidString)"
        run.customNPCs.removeAll { $0.id == id }
        run.pinnedReferenceIDs.removeAll { $0 == "npc:\(targetID)" }
        run.annotations.removeAll { $0.targetKind == .npc && $0.targetID == targetID }
        commit(run)
    }

    public func npc(id: String, in run: RunRecord) -> ContentPack.NPC? {
        if let npc = content.npcs.first(where: { $0.id == id }) {
            return npc
        }
        guard let custom = run.customNPCs.first(where: { "custom-npc-\($0.id.uuidString)" == id }) else { return nil }
        return ContentPack.NPC(
            id: id,
            name: custom.name,
            role: custom.role,
            publicDescription: custom.description,
            dmDescription: custom.description,
            keyCharacteristics: custom.keyCharacteristics,
            sourceText: custom.description
        )
    }
}
