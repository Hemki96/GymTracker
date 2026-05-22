import Testing
@testable import GymTracker

struct VolumeCalculatorTests {
    private let calculator = VolumeCalculator()

    @Test
    func setVolumeMultipliesWeightAndReps() {
        #expect(calculator.setVolume(weightKg: 80, reps: 5) == 400)
        #expect(calculator.setVolume(weightKg: 62.5, reps: 8) == 500)
    }

    @Test
    func setVolumeReturnsZeroForMissingOrInvalidValues() {
        #expect(calculator.setVolume(weightKg: nil, reps: 5) == 0)
        #expect(calculator.setVolume(weightKg: 80, reps: nil) == 0)
        #expect(calculator.setVolume(weightKg: 0, reps: 5) == 0)
        #expect(calculator.setVolume(weightKg: 80, reps: 0) == 0)
        #expect(calculator.setVolume(weightKg: -80, reps: 5) == 0)
        #expect(calculator.setVolume(weightKg: 80, reps: -5) == 0)
    }

    @Test
    func totalVolumeSumsCompletedWorkingSets() {
        let sets = [
            SetLog(setNumber: 1, loggedReps: 5, loggedWeightKg: 80, isCompleted: true),
            SetLog(setNumber: 2, loggedReps: 5, loggedWeightKg: 80, isCompleted: true),
            SetLog(setNumber: 3, loggedReps: 5, loggedWeightKg: 80, isWarmup: true, isCompleted: true),
            SetLog(setNumber: 4, loggedReps: 5, loggedWeightKg: 80, isCompleted: false)
        ]

        #expect(calculator.totalVolumeKg(from: sets) == 800)
        #expect(calculator.totalVolumeKg(from: sets, includeWarmups: true) == 1_200)
    }

    @Test
    func bodyweightExerciseCanUseRepetitionVolume() {
        #expect(calculator.setVolume(weightKg: nil, reps: 12) == 0)
        #expect(calculator.repetitionVolume(reps: 12) == 12)
        #expect(calculator.repetitionVolume(reps: nil) == 0)
        #expect(calculator.repetitionVolume(reps: -1) == 0)
    }
}
