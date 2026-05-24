import Testing
import Foundation
import SwiftData
@testable import GymTracker

@Suite(.serialized)
struct DashboardViewModelTests {
    @Test
    func exposesEmptyDashboardSummary() {
        let viewModel = DashboardViewModel(summary: .empty)

        #expect(viewModel.title == "Dashboard")
        #expect(viewModel.subtitle == "Dein Trainingsueberblick entsteht hier.")
    }
}

@Suite(.serialized)
struct TrainingPlanEditorViewModelTests {
    @Test
    @MainActor
    func validatesRequiredPlanAndNestedNames() throws {
        let context = try Self.makeContext()
        let viewModel = TrainingPlanEditorViewModel(context: context)
        let plan = TrainingPlan(name: "   ", goal: "")
        let week = TrainingWeek(weekNumber: 1, title: "")
        let session = TrainingSession(dayNumber: 1, title: " ", sortOrder: 1)
        let exercise = Exercise(name: "")

        #expect(viewModel.validate(plan).contains(.required("Name")))
        #expect(viewModel.validate(week).contains(.required("Wochentitel")))
        #expect(viewModel.validate(session).contains(.required("Session-Titel")))
        #expect(viewModel.validate(exercise).contains(.required("Uebungsname")))
    }

    @Test
    @MainActor
    func editsPlanMetadataAndStatus() throws {
        let context = try Self.makeContext()
        let viewModel = TrainingPlanEditorViewModel(context: context)
        let plan = TrainingPlan(name: "Alt", goal: "")
        context.insert(plan)

        try viewModel.updatePlan(
            plan,
            name: "Hypertrophie",
            description: "Vier Tage",
            goal: "Muskelaufbau",
            startDate: Date(timeIntervalSince1970: 1_800_000_000),
            status: .active
        )

        #expect(plan.name == "Hypertrophie")
        #expect(plan.descriptionText == "Vier Tage")
        #expect(plan.goal == "Muskelaufbau")
        #expect(plan.status == .active)
        #expect(plan.startDate == Date(timeIntervalSince1970: 1_800_000_000))
    }

    @Test
    @MainActor
    func duplicatesWholePlanGraphWithNewIdentities() throws {
        let context = try Self.makeContext()
        let viewModel = TrainingPlanEditorViewModel(context: context)
        let plan = Self.samplePlan()
        context.insert(plan)
        try context.save()

        let copy = try viewModel.duplicatePlan(plan)

        #expect(copy.id != plan.id)
        #expect(copy.name == "Original Kopie")
        #expect(copy.weeks.count == 1)
        let copiedWeek = try #require(copy.weeks.first)
        let copiedSession = try #require(copiedWeek.workoutPlans.first)
        let copiedExercise = try #require(copiedSession.plannedExercises.first)
        let copiedSet = try #require(copiedExercise.plannedSets.first)
        #expect(copiedWeek.id != plan.weeks[0].id)
        #expect(copiedSession.id != plan.weeks[0].workoutPlans[0].id)
        #expect(copiedExercise.id != plan.weeks[0].workoutPlans[0].plannedExercises[0].id)
        #expect(copiedSet.id != plan.weeks[0].workoutPlans[0].plannedExercises[0].plannedSets[0].id)
        #expect(copiedSession.focus == "Push")
        #expect(copiedSession.plannedDurationMinutes == 55)
        #expect(copiedExercise.exercise?.muscleGroup == "Brust")
        #expect(copiedSet.setType == .working)
        #expect(copiedSet.restText == "120s")
    }

    @Test
    @MainActor
    func addsDuplicatesMovesAndDeletesNestedEditorItems() throws {
        let context = try Self.makeContext()
        let viewModel = TrainingPlanEditorViewModel(context: context)
        let plan = TrainingPlan(name: "Plan", goal: "")
        context.insert(plan)

        let week = try viewModel.addWeek(to: plan)
        try viewModel.updateWeek(week, title: "Woche A", focus: "Technik", notes: "Locker")
        let copiedWeek = try viewModel.duplicateWeek(week, in: plan)
        try viewModel.moveWeek(copiedWeek, in: plan, direction: .up)

        let orderedWeeks = plan.weeks.sorted { $0.weekNumber < $1.weekNumber }
        #expect(orderedWeeks.map(\.title) == ["Woche A Kopie", "Woche A"])
        #expect(orderedWeeks.map(\.weekNumber) == [1, 2])

        let session = try viewModel.addSession(to: week)
        try viewModel.updateSession(session, title: "Upper", focus: "Push", plannedDurationMinutes: 60, notes: "Ruhig")
        let copiedSession = try viewModel.duplicateSession(session, in: week)
        try viewModel.moveSession(copiedSession, in: week, direction: .up)

        let orderedSessions = week.workoutPlans.sorted { $0.sortOrder < $1.sortOrder }
        #expect(orderedSessions.map(\.title) == ["Upper Kopie", "Upper"])
        #expect(orderedSessions.map(\.sortOrder) == [1, 2])

        let plannedExercise = try viewModel.addExercise(to: session)
        try viewModel.updateExercise(
            plannedExercise,
            name: "Bankdruecken",
            muscleGroup: "Brust",
            equipment: "Langhantel",
            cueing: "Schulterblaetter fest",
            tempo: "3-1-1",
            targetRIR: "2",
            painTarget: "max 2/10",
            notes: "Sauber"
        )
        let copiedExercise = try viewModel.duplicateExercise(plannedExercise, in: session)
        try viewModel.moveExercise(copiedExercise, in: session, direction: .up)

        let orderedExercises = session.plannedExercises.sorted { $0.sortOrder < $1.sortOrder }
        #expect(orderedExercises.map { $0.exercise?.name ?? "" } == ["Bankdruecken Kopie", "Bankdruecken"])
        #expect(orderedExercises.map(\.sortOrder) == [1, 2])

        let set = try viewModel.addSet(to: plannedExercise)
        try viewModel.updateSet(
            set,
            reps: "8-10",
            weight: "80 kg",
            targetRIR: "2",
            rest: "120s",
            tempo: "3-1-1",
            setType: .working,
            painTarget: "max 2/10",
            notes: "Topset"
        )
        let copiedSet = try viewModel.duplicateSet(set, in: plannedExercise)
        try viewModel.moveSet(copiedSet, in: plannedExercise, direction: .up)

        let orderedSets = plannedExercise.plannedSets.sorted { $0.setNumber < $1.setNumber }
        #expect(orderedSets.map(\.repsText) == ["8-10", "8-10"])
        #expect(orderedSets.map(\.setNumber) == [1, 2])

        try viewModel.deleteSet(copiedSet, from: plannedExercise)
        try viewModel.deleteExercise(copiedExercise, from: session)
        try viewModel.deleteSession(copiedSession, from: week)
        try viewModel.deleteWeek(copiedWeek, from: plan)

        #expect(plannedExercise.plannedSets.count == 1)
        #expect(session.plannedExercises.count == 1)
        #expect(week.workoutPlans.count == 1)
        #expect(plan.weeks.count == 1)
    }

    @Test
    @MainActor
    func updateSetSynchronizesParentPrescriptionFromTrimmedUniqueValues() throws {
        let context = try Self.makeContext()
        let viewModel = TrainingPlanEditorViewModel(context: context)
        let plannedExercise = PlannedExercise(
            sortOrder: 1,
            setsPrescription: "0",
            repsPrescription: "",
            plannedWeightText: nil,
            targetRIRText: nil,
            painTargetText: nil,
            exercise: Exercise(name: "Split Squat")
        )
        context.insert(plannedExercise)
        let firstSet = try viewModel.addSet(to: plannedExercise)
        let secondSet = try viewModel.addSet(to: plannedExercise)

        try viewModel.updateSet(
            firstSet,
            reps: " 8-10 ",
            weight: " 24 kg ",
            targetRIR: " 2 ",
            rest: " 90s ",
            tempo: " 3-1-1 ",
            setType: .working,
            painTarget: " max 3/10 ",
            notes: " Topset "
        )
        try viewModel.updateSet(
            secondSet,
            reps: "8-10",
            weight: "26 kg",
            targetRIR: "1",
            rest: "  ",
            tempo: nil,
            setType: .working,
            painTarget: "max 4/10",
            notes: nil
        )

        #expect(plannedExercise.setsPrescription == "2")
        #expect(plannedExercise.repsPrescription == "8-10")
        #expect(plannedExercise.plannedWeightText == "24 kg")
        #expect(plannedExercise.targetRIRText == "2")
        #expect(plannedExercise.painTargetText == "max 3/10")
        #expect(firstSet.restText == "90s")
        #expect(firstSet.tempo == "3-1-1")
        #expect(firstSet.notes == "Topset")
        #expect(secondSet.restText == nil)
    }

    @MainActor
    private static func makeContext() throws -> ModelContext {
        let schema = Schema([
            PersistentTrainingMarker.self,
            TrainingBlock.self,
            TrainingWeek.self,
            WorkoutPlan.self,
            Exercise.self,
            PlannedExercise.self,
            PlannedSet.self,
            SessionLog.self,
            ExerciseLog.self,
            SetLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private static func samplePlan() -> TrainingPlan {
        let plan = TrainingPlan(name: "Original", goal: "Kraft")
        let week = TrainingWeek(weekNumber: 1, title: "Woche 1", focus: "Volumen")
        let session = TrainingSession(dayNumber: 1, title: "Upper", sortOrder: 1)
        session.focus = "Push"
        session.plannedDurationMinutes = 55
        session.notes = "Kontrolliert"
        let exercise = Exercise(name: "Bankdruecken", category: .push)
        exercise.muscleGroup = "Brust"
        exercise.equipment = "Langhantel"
        let plannedExercise = PlannedExercise(
            sortOrder: 1,
            cueing: "Fest",
            tempo: "3-1-1",
            setsPrescription: "1",
            repsPrescription: "8-10",
            plannedWeightText: "80 kg",
            targetRIRText: "2",
            painTargetText: "max 2/10",
            workoutPlan: session,
            exercise: exercise
        )
        let set = PlannedSet(
            setNumber: 1,
            repsText: "8-10",
            weightText: "80 kg",
            targetRIRText: "2",
            painTargetText: "max 2/10",
            plannedExercise: plannedExercise
        )
        set.restText = "120s"
        set.tempo = "3-1-1"
        set.setType = .working
        plan.weeks = [week]
        week.workoutPlans = [session]
        session.plannedExercises = [plannedExercise]
        plannedExercise.plannedSets = [set]
        return plan
    }
}

@Suite(.serialized)
struct PlanViewPresentationTests {
    @Test
    @MainActor
    func overviewShowsEmptyStateWhenNoPlansExist() throws {
        let viewModel = PlanOverviewViewModel(plans: [])

        #expect(viewModel.isEmpty)
        #expect(viewModel.emptyTitle == "Noch kein Trainingsplan")
        #expect(viewModel.sections.map { $0.plans.count } == [0, 0, 0])
    }

    @Test
    @MainActor
    func overviewGroupsPlansByLifecycleAndMarksDemoPlans() throws {
        let active = TrainingPlan(name: "Kraftaufbau", goal: "Staerker werden", status: .active)
        let draft = TrainingPlan(name: "Hypertrophie Entwurf", goal: "Muskelaufbau", status: .planned)
        let archived = TrainingPlan(name: "Sommerblock", goal: "Erhaltung", status: .archived)
        let demo = TrainingPlan(
            name: "Demo Ganzkoerper",
            goal: "Ausprobieren",
            status: .planned,
            isDemoPlan: true,
            demoSourceIdentifier: "demo"
        )

        let viewModel = PlanOverviewViewModel(plans: [archived, demo, active, draft])

        #expect(!viewModel.isEmpty)
        #expect(viewModel.activePlans.map(\.name) == ["Kraftaufbau"])
        #expect(viewModel.draftPlans.map(\.name) == ["Demo Ganzkoerper", "Hypertrophie Entwurf"])
        #expect(viewModel.archivedPlans.map(\.name) == ["Sommerblock"])
        #expect(viewModel.badgeText(for: demo) == "Demo")
        #expect(viewModel.badgeText(for: draft) == "Entwurf")
    }

    @Test
    @MainActor
    func visibleWeeksDoesNotAssumeFixedDemoWeekRange() {
        let weekSeven = TrainingWeek(weekNumber: 7, title: "Week 7")
        let weekEight = TrainingWeek(weekNumber: 8, title: "Week 8")

        let visibleWeeks = PlanView.visibleWeeks(from: [weekEight, weekSeven])

        #expect(visibleWeeks.map(\.weekNumber) == [7, 8])
    }

    @Test
    @MainActor
    func visibleWorkoutsAndSummaryTextUseActualTrainingDays() {
        let week = TrainingWeek(weekNumber: 1, title: "Week 1")
        let dayFour = WorkoutPlan(dayNumber: 4, title: "Upper Body", sortOrder: 20)
        let dayTwo = WorkoutPlan(dayNumber: 2, title: "Lower Body", sortOrder: 10)
        week.workoutPlans = [dayFour, dayTwo]

        let workouts = PlanView.visibleWorkouts(for: week)

        #expect(workouts.map(\.dayNumber) == [2, 4])
        #expect(PlanView.trainingDaySummary(for: workouts) == "2 Trainingstage")
    }
}
