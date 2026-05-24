import Foundation
import SwiftData

@MainActor
struct PlanActionService {
    // MARK: - Properties

    private let context: ModelContext
    private let demoDataService: DemoDataService
    private let seedDataService: SeedDataService

    // MARK: - Lifecycle

    init(
        context: ModelContext,
        demoDataService: DemoDataService = DemoDataService(),
        seedDataService: SeedDataService = SeedDataService()
    ) {
        self.context = context
        self.demoDataService = demoDataService
        self.seedDataService = seedDataService
    }

    // MARK: - Creation and Import

    @discardableResult
    func createPlan() throws -> TrainingPlan {
        let plan = TrainingPlan(
            name: "Neuer Trainingsplan",
            goal: "",
            status: .planned
        )
        context.insert(plan)
        try context.save()
        return plan
    }

    @discardableResult
    func loadDemoPlan(existingPlans: [TrainingPlan]) throws -> TrainingPlan? {
        let knownIDs = Set(existingPlans.map(\.id))
        // SwiftData @Query refreshes asynchronously relative to this button
        // action, so we fetch the newest unknown plan after import instead of
        // assuming the caller's existingPlans array has already changed.
        _ = try demoDataService.loadBundledDemoPlan(into: context)
        return try newestPlan(excluding: knownIDs) ?? existingPlans.first(where: \.isDemoPlan) ?? firstDemoPlan()
    }

    @discardableResult
    func importPlan(from result: Result<[URL], Error>, existingPlans: [TrainingPlan]) throws -> TrainingPlan? {
        guard let url = try result.get().first else { return nil }
        let knownIDs = Set(existingPlans.map(\.id))
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        _ = try seedDataService.importSeedPlan(from: url, into: context)
        return try newestPlan(excluding: knownIDs)
    }

    // MARK: - Mutations

    @discardableResult
    func duplicate(_ plan: TrainingPlan) throws -> TrainingPlan {
        try demoDataService.duplicateDemoPlan(plan, name: "\(plan.name) Kopie", in: context)
    }

    func archive(_ plan: TrainingPlan, at date: Date = .now) throws {
        plan.status = .archived
        plan.updatedAt = date
        try context.save()
    }

    func delete(_ plan: TrainingPlan) throws {
        context.delete(plan)
        try context.save()
    }

    // MARK: - Queries

    private func newestPlan(excluding knownIDs: Set<UUID>) throws -> TrainingPlan? {
        let descriptor = FetchDescriptor<TrainingPlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first { !knownIDs.contains($0.id) }
    }

    private func firstDemoPlan() throws -> TrainingPlan? {
        let descriptor = FetchDescriptor<TrainingPlan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).first(where: \.isDemoPlan)
    }
}
