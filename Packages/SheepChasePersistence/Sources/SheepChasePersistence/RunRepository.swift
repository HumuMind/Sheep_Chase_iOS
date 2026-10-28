import Foundation
import SheepChaseCore
import SwiftData

@MainActor
public final class RunRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func fetchAll() -> [RunRecord] {
        let descriptor = FetchDescriptor<RunRecord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    public func insert(_ run: RunRecord) {
        context.insert(run)
    }

    public func delete(_ run: RunRecord) {
        context.delete(run)
    }

    public func save() {
        try? context.save()
    }
}
