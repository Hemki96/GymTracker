import SwiftData
import SwiftUI

struct WorkoutDetailView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Properties

    let workout: WorkoutPlan

    // MARK: - State

    @State private var activeSession: SessionLog?
    @State private var sessionStartError: String?

    // MARK: - Derived State

    private var weekNumber: Int {
        workout.week?.weekNumber ?? 0
    }

    private var exercises: [PlannedExercise] {
        workout.plannedExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                DashboardCard(
                    title: workout.title,
                    subtitle: "\(exercises.count) Uebungen",
                    systemImage: "dumbbell"
                ) {
                    HStack {
                        Text("Woche \(weekNumber) · Tag \(workout.dayNumber)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        WorkoutStatusBadge(status: workout.status)
                    }

                    if let focus = workout.focus, !focus.isEmpty {
                        Label(focus, systemImage: "target")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let plannedDurationMinutes = workout.plannedDurationMinutes {
                        Label("\(plannedDurationMinutes) Minuten geplant", systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let notes = workout.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(exercises, id: \.id) { exercise in
                    ExercisePlanRow(plannedExercise: exercise)
                }
            }
            .padding(AppTheme.Spacing.screen)
        }
        .appGroupedBackground()
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                startOrResumeSession()
            } label: {
                Label(sessionButtonTitle, systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .controlSize(.large)
            .padding(AppTheme.Spacing.large)
            .appFloatingBarSurface()
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

    // MARK: - Display

    private var sessionButtonTitle: String {
        workout.sessionLogs.contains { $0.status == .active } ? "Session fortsetzen" : "Training starten"
    }

    // MARK: - Bindings

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

    // MARK: - Actions

    private func startOrResumeSession() {
        let service = SessionStartService(context: modelContext)

        do {
            activeSession = try service.startOrResumeSession(from: workout)
        } catch SessionStartError.activeSessionAlreadyExists {
            // The service enforces a single active session globally. The view
            // keeps that rule visible instead of silently opening the wrong
            // workout's session.
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
