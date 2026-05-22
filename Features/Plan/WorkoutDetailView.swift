import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    let workout: WorkoutPlan

    private var weekNumber: Int {
        workout.week?.weekNumber ?? 0
    }

    private var exercises: [PlannedExercise] {
        workout.plannedExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Woche \(weekNumber) · Tag \(workout.dayNumber)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        WorkoutStatusBadge(status: workout.status)
                    }

                    Text(workout.title)
                        .font(.largeTitle.bold())
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)

                    Text("\(exercises.count) Übungen")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.large)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemGroupedBackground))
                }

                ForEach(exercises, id: \.id) { exercise in
                    ExercisePlanRow(plannedExercise: exercise)
                }
            }
            .padding(AppTheme.Spacing.screen)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let context = ModelContext(PlanPreviewData.container)
    let workouts = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
    let workout = workouts.first { $0.week?.weekNumber == 1 && $0.dayNumber == 1 } ?? workouts[0]

    NavigationStack {
        WorkoutDetailView(workout: workout)
    }
}
