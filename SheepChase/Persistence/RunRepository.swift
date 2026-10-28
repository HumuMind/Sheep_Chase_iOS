import Foundation
import SwiftData

@MainActor
final class RunRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() -> [RunRecord] {
        let descriptor = FetchDescriptor<RunRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func insert(_ run: RunRecord) {
        context.insert(run)
    }

    func delete(_ run: RunRecord) {
        context.delete(run)
    }

    func save() {
        try? context.save()
    }
}
