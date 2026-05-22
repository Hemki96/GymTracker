import Testing
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
struct PlanViewPresentationTests {
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
