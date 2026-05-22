import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let workout: WorkoutPlan
    @State private var activeSession: SessionLog?
    @State private var sessionStartError: String?

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
        .safeAreaInset(edge: .bottom) {
            Button {
                startOrResumeSession()
            } label: {
                Label(sessionButtonTitle, systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(AppTheme.Spacing.large)
            .background(.regularMaterial)
        }
        .navigationDestination(isPresented: activeSessionBinding) {
            if let activeSession {
                ActiveSessionView(sessionLog: activeSession)
            }
        }
        .alert("Session kann nicht gestartet werden", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                sessionStartError = nil
            }
        } message: {
            Text(sessionStartError ?? "")
        }
    }

    private var sessionButtonTitle: String {
        workout.sessionLogs.contains { $0.status == .active } ? "Session fortsetzen" : "Training starten"
    }

    private var errorBinding: Binding<Bool> {
        Binding {
            sessionStartError != nil
        } set: { isPresented in
            if !isPresented {
                sessionStartError = nil
            }
        }
    }

    private var activeSessionBinding: Binding<Bool> {
        Binding {
            activeSession != nil
        } set: { isPresented in
            if !isPresented {
                activeSession = nil
            }
        }
    }

    private func startOrResumeSession() {
        if let existingSession = workout.sessionLogs.first(where: { $0.status == .active }) {
            activeSession = existingSession
            return
        }

        let service = SessionStartService(context: modelContext)

        do {
            activeSession = try service.startSession(from: workout)
        } catch SessionStartError.activeSessionAlreadyExists {
            sessionStartError = "Es läuft bereits eine andere aktive Session. Beende diese zuerst oder öffne sie über den aktuellen Workout-Kontext."
        } catch {
            sessionStartError = "Die Session konnte nicht gespeichert werden."
        }
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
