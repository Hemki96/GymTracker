import Foundation

struct VolumeCalculator {
    func setVolume(weightKg: Double?, reps: Int?) -> Double {
        guard let weightKg, let reps, weightKg > 0, reps > 0 else { return 0 }
        return weightKg * Double(reps)
    }

    func totalVolumeKg(from setLogs: [SetLog], includeWarmups: Bool = false) -> Double {
        setLogs.reduce(0) { total, setLog in
            guard setLog.isCompleted, includeWarmups || !setLog.isWarmup else { return total }
            return total + setVolume(weightKg: setLog.loggedWeightKg, reps: setLog.loggedReps)
        }
    }

    func repetitionVolume(reps: Int?) -> Int {
        guard let reps, reps > 0 else { return 0 }
        return reps
    }
}
