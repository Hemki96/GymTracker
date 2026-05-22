import SwiftData
import SwiftUI

struct ActiveSessionView: View {
    @Environment(\.modelContext) private var modelContext

    let sessionLog: SessionLog

    @State private var selectedExerciseID: UUID?
    @State private var completedSession: SessionLog?
    @State private var sessionError: String?

    private var exerciseLogs: [ExerciseLog] {
        sessionLog.exerciseLogs.sorted {
            ($0.plannedExercise?.sortOrder ?? 0) < ($1.plannedExercise?.sortOrder ?? 0)
        }
    }

    private var selectedIndex: Int {
        guard let selectedExerciseID,
              let index = exerciseLogs.firstIndex(where: { $0.id == selectedExerciseID }) else {
            return 0
        }

        return index
    }

    private var selectedExerciseLog: ExerciseLog? {
        guard exerciseLogs.indices.contains(selectedIndex) else {
            return nil
        }

        return exerciseLogs[selectedIndex]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                sessionHeader

                if let selectedExerciseLog {
                    ExerciseTrackingView(exerciseLog: selectedExerciseLog) {
                        saveSession()
                    }
                } else {
                    ContentUnavailableView(
                        "Keine Übungen",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Diese Session enthält noch keine geplanten Übungen.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                }
            }
            .padding(AppTheme.Spacing.screen)
        }
        .appGroupedBackground()
        .navigationTitle("Aktive Session")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                completeSession()
            } label: {
                Label("Session abschließen", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(AppTheme.Spacing.large)
            .appFloatingBarSurface()
        }
        .navigationDestination(isPresented: completedSessionBinding) {
            if let completedSession {
                SessionSummaryView(sessionLog: completedSession)
            }
        }
        .alert("Session konnte nicht gespeichert werden", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                sessionError = nil
            }
        } message: {
            Text(sessionError ?? "")
        }
        .onAppear {
            selectedExerciseID = selectedExerciseID ?? exerciseLogs.first?.id
        }
    }

    private var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionLog.workoutPlan?.title ?? "Training")
                        .font(.title2.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text("Übung \(min(selectedIndex + 1, exerciseLogs.count)) von \(exerciseLogs.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Text("Live")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background {
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    }
            }

            HStack(spacing: 12) {
                Button {
                    moveSelection(by: -1)
                } label: {
                    Label("Zurück", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.bordered)
                .disabled(selectedIndex == 0)

                Button {
                    moveSelection(by: 1)
                } label: {
                    Label("Weiter", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedIndex >= exerciseLogs.count - 1)
            }
            .controlSize(.large)
        }
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }

    private func moveSelection(by offset: Int) {
        let nextIndex = selectedIndex + offset
        guard exerciseLogs.indices.contains(nextIndex) else {
            return
        }

        selectedExerciseID = exerciseLogs[nextIndex].id
    }

    private func saveSession() {
        sessionLog.updatedAt = .now
        SessionCompletionService(context: modelContext).refreshSummary(for: sessionLog)
        do {
            try modelContext.save()
        } catch {
            sessionError = "Deine Eingaben sind noch sichtbar, konnten aber nicht dauerhaft gespeichert werden."
        }
    }

    private var completedSessionBinding: Binding<Bool> {
        Binding {
            completedSession != nil
        } set: { isPresented in
            if !isPresented {
                completedSession = nil
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding {
            sessionError != nil
        } set: { isPresented in
            if !isPresented {
                sessionError = nil
            }
        }
    }

    private func completeSession() {
        do {
            let completed = try SessionCompletionService(context: modelContext).completeSession(
                sessionLog,
                note: sessionLog.overallNotes
            )
            completedSession = completed
        } catch {
            sessionError = "Die Session konnte nicht abgeschlossen werden. Bitte prüfe die Eingaben und versuche es erneut."
        }
    }
}

struct ExerciseTrackingView: View {
    @Environment(\.modelContext) private var modelContext

    let exerciseLog: ExerciseLog
    let onSave: () -> Void
    @State private var editingError: String?

    private var setLogs: [SetLog] {
        exerciseLog.setLogs.sorted { $0.setNumber < $1.setNumber }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            ExerciseHeaderCard(exerciseLog: exerciseLog)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sätze")
                        .font(.title3.weight(.semibold))

                    Spacer()

                    Button {
                        addSet()
                    } label: {
                        Label("Satz", systemImage: "plus")
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                ForEach(setLogs, id: \.id) { setLog in
                    SetLogRow(setLog: setLog, canDelete: setLogs.count > 1, onDelete: {
                        deleteSet(setLog)
                    }, onSave: onSave)
                }
            }
        }
        .alert("Satz konnte nicht gespeichert werden", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                editingError = nil
            }
        } message: {
            Text(editingError ?? "")
        }
    }

    private func addSet() {
        do {
            try SessionEditingService(context: modelContext).addSet(to: exerciseLog)
            onSave()
        } catch {
            editingError = "Der neue Satz konnte nicht dauerhaft gespeichert werden."
        }
    }

    private func deleteSet(_ setLog: SetLog) {
        do {
            try SessionEditingService(context: modelContext).deleteSet(setLog)
            onSave()
        } catch {
            editingError = "Der Satz konnte nicht gelöscht werden."
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding {
            editingError != nil
        } set: { isPresented in
            if !isPresented {
                editingError = nil
            }
        }
    }
}

struct SetLogRow: View {
    @Bindable var setLog: SetLog
    let canDelete: Bool
    let onDelete: () -> Void
    let onSave: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var saveError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button {
                    setLog.isCompleted.toggle()
                    save()
                } label: {
                    Label(
                        setLog.isCompleted ? "Erledigt" : "Offen",
                        systemImage: setLog.isCompleted ? "checkmark.circle.fill" : "circle"
                    )
                    .frame(minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(setLog.isCompleted ? .green : .secondary)
                .controlSize(.large)
                .accessibilityLabel(setLog.isCompleted ? "Satz als offen markieren" : "Satz als erledigt markieren")

                Spacer()

                Text("Satz \(setLog.setNumber)")
                    .font(.headline)

                if canDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Satz löschen")
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                editableNumberField(
                    title: "Gewicht",
                    value: weightBinding,
                    placeholder: setLog.plannedWeightText ?? "kg",
                    keyboard: .decimalPad,
                    suffix: "kg"
                )

                editableNumberField(
                    title: "Reps",
                    value: repsBinding,
                    placeholder: setLog.plannedRepsText ?? "Wdh.",
                    keyboard: .numberPad,
                    suffix: nil
                )
            }

            HStack(alignment: .top, spacing: 12) {
                RIRPicker(value: rirBinding)
                PainPicker(value: painBinding)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Notiz")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Optional", text: notesBinding, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .frame(minHeight: 44)
            }
        }
        .padding(AppTheme.Spacing.large)
        .appSetLogSurface(isCompleted: setLog.isCompleted)
        .alert("Satz konnte nicht gespeichert werden", isPresented: saveErrorBinding) {
            Button("OK", role: .cancel) {
                saveError = nil
            }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func editableNumberField(
        title: String,
        value: Binding<String>,
        placeholder: String,
        keyboard: UIKeyboardType,
        suffix: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
            TextField(placeholder, text: value)
                    .keyboardType(keyboard)
                    .font(.title3.weight(.semibold))
                    .minimumScaleFactor(0.82)
                    .accessibilityLabel(title)

                if let suffix {
                    Text(suffix)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 50)
            .padding(.horizontal, 12)
            .appControlSurface()
        }
    }

    private var weightBinding: Binding<String> {
        Binding {
            guard let loggedWeightKg = setLog.loggedWeightKg else {
                return ""
            }

            return loggedWeightKg.formatted(.number.precision(.fractionLength(0...2)))
        } set: { newValue in
            setLog.loggedWeightKg = Double(newValue.replacingOccurrences(of: ",", with: "."))
            save()
        }
    }

    private var repsBinding: Binding<String> {
        Binding {
            guard let loggedReps = setLog.loggedReps else {
                return ""
            }

            return "\(loggedReps)"
        } set: { newValue in
            setLog.loggedReps = Int(newValue)
            save()
        }
    }

    private var rirBinding: Binding<Double?> {
        Binding {
            setLog.rir
        } set: { newValue in
            setLog.rir = newValue
            save()
        }
    }

    private var painBinding: Binding<Int?> {
        Binding {
            setLog.pain
        } set: { newValue in
            setLog.pain = newValue
            save()
        }
    }

    private var notesBinding: Binding<String> {
        Binding {
            setLog.notes ?? ""
        } set: { newValue in
            setLog.notes = newValue.isEmpty ? nil : newValue
            save()
        }
    }

    private func save() {
        do {
            try SessionEditingService(context: modelContext).save(setLog: setLog)
            onSave()
        } catch {
            saveError = "Die Änderung bleibt sichtbar, konnte aber nicht dauerhaft gespeichert werden."
        }
    }

    private var saveErrorBinding: Binding<Bool> {
        Binding {
            saveError != nil
        } set: { isPresented in
            if !isPresented {
                saveError = nil
            }
        }
    }
}

struct RIRPicker: View {
    @Binding var value: Double?

    private let values: [Double] = [0, 1, 2, 3, 4, 5]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("RIR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Menu {
                Button("Keine Angabe") {
                    value = nil
                }

                ForEach(values, id: \.self) { option in
                    Button(option.formatted(.number.precision(.fractionLength(0)))) {
                        value = option
                    }
                }
            } label: {
                HStack {
                    Text(displayValue)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 50)
                .padding(.horizontal, 12)
                .appControlSurface()
            }
            .buttonStyle(.plain)
        }
    }

    private var displayValue: String {
        guard let value else {
            return "-"
        }

        return value.formatted(.number.precision(.fractionLength(0...1)))
    }
}

struct PainPicker: View {
    @Binding var value: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Schmerz")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Menu {
                Button("Keine Angabe") {
                    value = nil
                }

                ForEach(0...10, id: \.self) { option in
                    Button("\(option)") {
                        value = option
                    }
                }
            } label: {
                HStack {
                    Text(displayValue)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 50)
                .padding(.horizontal, 12)
                .appPainControlSurface(painColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var displayValue: String {
        guard let value else {
            return "-"
        }

        return "\(value)"
    }

    private var painColor: Color {
        guard let value else {
            return Color(.tertiarySystemGroupedBackground)
        }

        switch value {
        case 0...3:
            return .green
        case 4...6:
            return .orange
        default:
            return .red
        }
    }
}

struct ExerciseHeaderCard: View {
    let exerciseLog: ExerciseLog

    private var plannedExercise: PlannedExercise? {
        exerciseLog.plannedExercise
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Aktuelle Übung")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(plannedExercise?.exercise?.name ?? "Unbekannte Übung")
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.62)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
                planValue(title: "Sätze", value: plannedExercise?.setsPrescription)
                planValue(title: "Wdh.", value: plannedExercise?.repsPrescription)
                planValue(title: "Gewicht", value: plannedExercise?.plannedWeightText)
                planValue(title: "Ziel-RIR", value: plannedExercise?.targetRIRText)
                planValue(title: "Schmerz", value: plannedExercise?.painTargetText)
                planValue(title: "Tempo", value: plannedExercise?.tempo)
            }

            if let cueing = plannedExercise?.cueing, !cueing.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cueing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(cueing)
                        .font(.body)
                }
            }

            if let notes = plannedExercise?.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plan-Notiz")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .font(.body)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }

    private func planValue(title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(displayValue(value))
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .appControlSurface()
    }

    private func displayValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "-"
        }

        return value
    }
}

#Preview {
    let context = ModelContext(PlanPreviewData.container)
    let workouts = (try? context.fetch(FetchDescriptor<WorkoutPlan>())) ?? []
    let workout = workouts.first { $0.week?.weekNumber == 1 && $0.dayNumber == 1 } ?? workouts[0]
    let service = SessionStartService(context: context)
    let session = (try? service.startSession(from: workout)) ?? workout.sessionLogs[0]

    NavigationStack {
        ActiveSessionView(sessionLog: session)
    }
}
