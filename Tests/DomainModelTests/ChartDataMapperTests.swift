import Foundation
import Testing
@testable import GymTracker

@Suite(.serialized)
struct ChartDataMapperTests {
    @Test
    func weeklyVolumeAggregatesCompletedSessionsByWeek() {
        let mapper = ChartDataMapper(calendar: gregorianCalendar)
        let monday = date(2026, 5, 18)
        let tuesday = date(2026, 5, 19)
        let nextMonday = date(2026, 5, 25)
        let sessions = [
            makeSession(completedAt: monday, totalVolumeKg: 1_000),
            makeSession(completedAt: tuesday, totalVolumeKg: 750),
            makeSession(completedAt: nextMonday, totalVolumeKg: 500),
            makeSession(completedAt: tuesday, status: .active, totalVolumeKg: 9_999)
        ]

        let points = mapper.weeklyVolume(from: sessions)

        #expect(points.count == 2)
        #expect(points[0].weekStart == monday)
        #expect(points[0].totalVolumeKg == 1_750)
        #expect(points[0].sessionCount == 2)
        #expect(points[1].weekStart == nextMonday)
        #expect(points[1].totalVolumeKg == 500)
        #expect(points[1].sessionCount == 1)
    }

    @Test
    func painAndRIRTrendsUseSessionSummariesAndSortByDate() {
        let mapper = ChartDataMapper(calendar: gregorianCalendar)
        let later = makeSession(
            completedAt: date(2026, 5, 21),
            maxPain: 5,
            averageRIR: 1.5
        )
        let earlier = makeSession(
            completedAt: date(2026, 5, 19),
            maxPain: 2,
            averageRIR: 3
        )
        let withoutMetrics = makeSession(completedAt: date(2026, 5, 20))

        let pain = mapper.painTrend(from: [later, withoutMetrics, earlier])
        let rir = mapper.rirTrend(from: [later, withoutMetrics, earlier])

        #expect(pain.map(\.value) == [2, 5])
        #expect(rir.map(\.value) == [3, 1.5])
        #expect(pain.map(\.date) == [date(2026, 5, 19), date(2026, 5, 21)])
    }

    @Test
    func metricTrendsFallbackToCompletedSetValues() {
        let mapper = ChartDataMapper(calendar: gregorianCalendar)
        let session = makeSession(
            completedAt: date(2026, 5, 20),
            sets: [
                SetLog(setNumber: 1, loggedReps: 5, loggedWeightKg: 80, rir: 2, pain: 3, isCompleted: true),
                SetLog(setNumber: 2, loggedReps: 5, loggedWeightKg: 82.5, rir: 1, pain: 4, isCompleted: true)
            ]
        )

        #expect(mapper.painTrend(from: [session]).first?.value == 4)
        #expect(mapper.rirTrend(from: [session]).first?.value == 1.5)
    }

    @Test
    func weightTrendUsesMaxCompletedWorkingSetForSelectedExercise() {
        let mapper = ChartDataMapper(calendar: gregorianCalendar)
        let squat = Exercise(name: "Kniebeugen", category: .squat)
        let press = Exercise(name: "Bankdruecken", category: .push)
        let first = makeSession(
            completedAt: date(2026, 5, 19),
            exercise: squat,
            sets: [
                SetLog(setNumber: 1, loggedReps: 5, loggedWeightKg: 80, isWarmup: true, isCompleted: true),
                SetLog(setNumber: 2, loggedReps: 5, loggedWeightKg: 100, isCompleted: true),
                SetLog(setNumber: 3, loggedReps: 5, loggedWeightKg: 105, isCompleted: false)
            ]
        )
        let second = makeSession(
            completedAt: date(2026, 5, 21),
            exercise: squat,
            sets: [
                SetLog(setNumber: 1, loggedReps: 3, loggedWeightKg: 102.5, isCompleted: true)
            ]
        )
        let otherExercise = makeSession(
            completedAt: date(2026, 5, 20),
            exercise: press,
            sets: [
                SetLog(setNumber: 1, loggedReps: 5, loggedWeightKg: 90, isCompleted: true)
            ]
        )

        let points = mapper.weightTrend(for: squat.id, in: [second, otherExercise, first])

        #expect(points.map(\.maxWeightKg) == [100, 102.5])
        #expect(points.allSatisfy { $0.exerciseID == squat.id })
    }

    @Test
    func exerciseOptionsAreUniqueAndSorted() {
        let mapper = ChartDataMapper(calendar: gregorianCalendar)
        let squat = Exercise(name: "Kniebeugen", category: .squat)
        let press = Exercise(name: "Bankdruecken", category: .push)

        let options = mapper.exerciseOptions(from: [
            makeSession(completedAt: date(2026, 5, 19), exercise: squat),
            makeSession(completedAt: date(2026, 5, 20), exercise: press),
            makeSession(completedAt: date(2026, 5, 21), exercise: squat)
        ])

        #expect(options.map(\.name) == ["Bankdruecken", "Kniebeugen"])
        #expect(Set(options.map(\.id)).count == 2)
    }

    private var gregorianCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "de_DE")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.calendar = gregorianCalendar
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = year
        components.month = month
        components.day = day
        return components.date!
    }

    private func makeSession(
        completedAt: Date,
        status: SessionStatus = .completed,
        totalVolumeKg: Double? = nil,
        maxPain: Int? = nil,
        averageRIR: Double? = nil,
        exercise: Exercise = Exercise(name: "Kniebeugen", category: .squat),
        sets: [SetLog] = []
    ) -> SessionLog {
        let workout = WorkoutPlan(dayNumber: 1, title: "Training", sortOrder: 1)
        let plannedExercise = PlannedExercise(
            sortOrder: 1,
            setsPrescription: "3",
            repsPrescription: "5",
            workoutPlan: workout,
            exercise: exercise
        )
        let exerciseLog = ExerciseLog(
            sessionLog: nil,
            plannedExercise: plannedExercise,
            setLogs: sets
        )
        for set in sets {
            set.exerciseLog = exerciseLog
        }

        let session = SessionLog(
            startedAt: completedAt.addingTimeInterval(-3_600),
            completedAt: status == .completed ? completedAt : nil,
            status: status,
            maxPain: maxPain,
            averageRIR: averageRIR,
            totalVolumeKg: totalVolumeKg,
            workoutPlan: workout,
            exerciseLogs: [exerciseLog]
        )
        exerciseLog.sessionLog = session
        return session
    }
}
