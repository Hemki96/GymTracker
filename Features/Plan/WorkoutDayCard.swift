import SwiftData
import SwiftUI

struct WorkoutDayCard: View {
    let workout: WorkoutPlan

    private var exercises: [PlannedExercise] {
        workout.plannedExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var keyExerciseNames: String {
        exercises
            .prefix(3)
            .compactMap { $0.exercise?.name }
            .joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tag \(workout.dayNumber)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(workout.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 12)

                WorkoutStatusBadge(status: workout.status)
            }

            if !keyExerciseNames.isEmpty {
                Text(keyExerciseNames)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Label("\(exercises.count) Übungen", systemImage: "list.bullet.clipboard")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(AppTheme.Spacing.large)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

struct WorkoutStatusBadge: View {
    let status: WorkoutStatus

    var body: some View {
        Text(status.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.foregroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(status.backgroundColor)
            }
    }
}

private extension WorkoutStatus {
    var title: String {
        switch self {
        case .planned:
            return "Geplant"
        case .active:
            return "Aktiv"
        case .completed:
            return "Abgeschlossen"
        case .skipped:
            return "Übersprungen"
        }
    }

    var foregroundColor: Color {
        switch self {
        case .planned:
            return .blue
        case .active:
            return .orange
        case .completed:
            return .green
        case .skipped:
            return .secondary
        }
    }

    var backgroundColor: Color {
        foregroundColor.opacity(0.14)
    }
}

#Preview {
    let context = ModelContext(PlanPreviewData.container)
    let workouts = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
    let workout = workouts.first { $0.week?.weekNumber == 1 && $0.dayNumber == 1 } ?? workouts[0]

    WorkoutDayCard(workout: workout)
        .padding()
        .background(Color(.systemGroupedBackground))
}
