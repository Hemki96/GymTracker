import SwiftData
import SwiftUI

struct TrainingPlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let plan: TrainingPlan
    @State private var name: String
    @State private var descriptionText: String
    @State private var goal: String
    @State private var hasStartDate: Bool
    @State private var startDate: Date
    @State private var status: BlockStatus
    @State private var errorMessage: String?
    @State private var isDeletingPlan = false

    private var viewModel: TrainingPlanEditorViewModel {
        TrainingPlanEditorViewModel(context: modelContext)
    }

    init(plan: TrainingPlan) {
        self.plan = plan
        _name = State(initialValue: plan.name)
        _descriptionText = State(initialValue: plan.descriptionText ?? "")
        _goal = State(initialValue: plan.goal)
        _hasStartDate = State(initialValue: plan.startDate != nil)
        _startDate = State(initialValue: plan.startDate ?? .now)
        _status = State(initialValue: plan.status)
    }

    var body: some View {
        Form {
            Section("Trainingsplan") {
                TextField("Name", text: $name)
                TextField("Beschreibung", text: $descriptionText, axis: .vertical)
                    .lineLimit(2...5)
                TextField("Ziel", text: $goal, axis: .vertical)
                    .lineLimit(2...5)
                Toggle("Startdatum setzen", isOn: $hasStartDate)
                if hasStartDate {
                    DatePicker("Startdatum", selection: $startDate, displayedComponents: .date)
                }
                Picker("Status", selection: $status) {
                    Text("Entwurf").tag(BlockStatus.planned)
                    Text("Aktiv").tag(BlockStatus.active)
                    Text("Archiviert").tag(BlockStatus.archived)
                }
            }

            Section {
                Button {
                    perform { _ = try viewModel.addWeek(to: plan) }
                } label: {
                    Label("Woche hinzufuegen", systemImage: "calendar.badge.plus")
                }
            }

            Section("Trainingswochen") {
                ForEach(weeks, id: \.id) { week in
                    NavigationLink {
                        TrainingWeekEditorView(week: week)
                    } label: {
                        PlanEditorRowTitle(
                            title: "Woche \(week.weekNumber): \(week.title)",
                            subtitle: week.focus
                        )
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            perform { try viewModel.deleteWeek(week, from: plan) }
                        } label: {
                            Label("Loeschen", systemImage: "trash")
                        }

                        Button {
                            perform { _ = try viewModel.duplicateWeek(week, in: plan) }
                        } label: {
                            Label("Duplizieren", systemImage: "plus.square.on.square")
                        }
                    }
                    .contextMenu {
                        moveDuplicateDeleteMenu(
                            moveUp: { try viewModel.moveWeek(week, in: plan, direction: .up) },
                            moveDown: { try viewModel.moveWeek(week, in: plan, direction: .down) },
                            duplicate: { _ = try viewModel.duplicateWeek(week, in: plan) },
                            delete: { try viewModel.deleteWeek(week, from: plan) }
                        )
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    isDeletingPlan = true
                } label: {
                    Label("Plan loeschen", systemImage: "trash")
                }
            }
        }
        .navigationTitle("Plan bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Schliessen") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Sichern") {
                    savePlan()
                }
            }
        }
        .confirmationDialog("Trainingsplan loeschen?", isPresented: $isDeletingPlan) {
            Button("Plan loeschen", role: .destructive) {
                perform {
                    try viewModel.deletePlan(plan)
                    dismiss()
                }
            }
        } message: {
            Text("Der Plan inklusive Wochen, Sessions, Uebungen und Saetzen wird dauerhaft entfernt.")
        }
        .alert("Editor-Aktion fehlgeschlagen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var weeks: [TrainingWeek] {
        plan.weeks.sorted { $0.weekNumber < $1.weekNumber }
    }

    private func savePlan() {
        perform {
            try viewModel.updatePlan(
                plan,
                name: name,
                description: descriptionText,
                goal: goal,
                startDate: hasStartDate ? startDate : nil,
                status: status
            )
        }
    }

    @ViewBuilder
    private func moveDuplicateDeleteMenu(
        moveUp: @escaping () throws -> Void,
        moveDown: @escaping () throws -> Void,
        duplicate: @escaping () throws -> Void,
        delete: @escaping () throws -> Void
    ) -> some View {
        Button { perform(moveUp) } label: { Label("Nach oben", systemImage: "arrow.up") }
        Button { perform(moveDown) } label: { Label("Nach unten", systemImage: "arrow.down") }
        Button { perform(duplicate) } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
        Button(role: .destructive) { perform(delete) } label: { Label("Loeschen", systemImage: "trash") }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch TrainingPlanEditorError.validationFailed(let issues) {
            errorMessage = issues.map(\.message).joined(separator: "\n")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TrainingWeekEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let week: TrainingWeek
    @State private var title: String
    @State private var focus: String
    @State private var notes: String
    @State private var errorMessage: String?

    private var viewModel: TrainingPlanEditorViewModel {
        TrainingPlanEditorViewModel(context: modelContext)
    }

    init(week: TrainingWeek) {
        self.week = week
        _title = State(initialValue: week.title)
        _focus = State(initialValue: week.focus ?? "")
        _notes = State(initialValue: week.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Woche") {
                TextField("Titel", text: $title)
                TextField("Wochenfokus", text: $focus, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Notizen", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                Button("Woche sichern") { saveWeek() }
            }

            Section {
                Button {
                    perform { _ = try viewModel.addSession(to: week) }
                } label: {
                    Label("Session hinzufuegen", systemImage: "plus.circle")
                }
            }

            Section("Sessions") {
                ForEach(sessions, id: \.id) { session in
                    NavigationLink {
                        TrainingSessionEditorView(session: session)
                    } label: {
                        PlanEditorRowTitle(title: "Tag \(session.dayNumber): \(session.title)", subtitle: session.focus)
                    }
                    .contextMenu {
                        Button { perform { try viewModel.moveSession(session, in: week, direction: .up) } } label: { Label("Nach oben", systemImage: "arrow.up") }
                        Button { perform { try viewModel.moveSession(session, in: week, direction: .down) } } label: { Label("Nach unten", systemImage: "arrow.down") }
                        Button { perform { _ = try viewModel.duplicateSession(session, in: week) } } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
                        Button(role: .destructive) { perform { try viewModel.deleteSession(session, from: week) } } label: { Label("Loeschen", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Woche bearbeiten")
        .alert("Editor-Aktion fehlgeschlagen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var sessions: [TrainingSession] {
        week.workoutPlans.sorted {
            if $0.sortOrder == $1.sortOrder { return $0.dayNumber < $1.dayNumber }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private func saveWeek() {
        perform { try viewModel.updateWeek(week, title: title, focus: focus, notes: notes) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch TrainingPlanEditorError.validationFailed(let issues) {
            errorMessage = issues.map(\.message).joined(separator: "\n")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TrainingSessionEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let session: TrainingSession
    @State private var title: String
    @State private var focus: String
    @State private var durationText: String
    @State private var notes: String
    @State private var errorMessage: String?

    private var viewModel: TrainingPlanEditorViewModel {
        TrainingPlanEditorViewModel(context: modelContext)
    }

    init(session: TrainingSession) {
        self.session = session
        _title = State(initialValue: session.title)
        _focus = State(initialValue: session.focus ?? "")
        _durationText = State(initialValue: session.plannedDurationMinutes.map(String.init) ?? "")
        _notes = State(initialValue: session.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Session") {
                TextField("Titel", text: $title)
                TextField("Session-Fokus", text: $focus, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Geplante Dauer in Minuten", text: $durationText)
                    .keyboardType(.numberPad)
                TextField("Notizen", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                Button("Session sichern") { saveSession() }
            }

            Section {
                Button {
                    perform { _ = try viewModel.addExercise(to: session) }
                } label: {
                    Label("Uebung hinzufuegen", systemImage: "plus.circle")
                }
            }

            Section("Uebungen") {
                ForEach(exercises, id: \.id) { exercise in
                    NavigationLink {
                        PlannedExerciseEditorView(plannedExercise: exercise)
                    } label: {
                        PlanEditorRowTitle(title: exercise.exercise?.name ?? "Unbekannte Uebung", subtitle: exercise.exercise?.muscleGroup)
                    }
                    .contextMenu {
                        Button { perform { try viewModel.moveExercise(exercise, in: session, direction: .up) } } label: { Label("Nach oben", systemImage: "arrow.up") }
                        Button { perform { try viewModel.moveExercise(exercise, in: session, direction: .down) } } label: { Label("Nach unten", systemImage: "arrow.down") }
                        Button { perform { _ = try viewModel.duplicateExercise(exercise, in: session) } } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
                        Button(role: .destructive) { perform { try viewModel.deleteExercise(exercise, from: session) } } label: { Label("Loeschen", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Session bearbeiten")
        .alert("Editor-Aktion fehlgeschlagen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var exercises: [PlannedExercise] {
        session.plannedExercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func saveSession() {
        let duration = Int(durationText.trimmingCharacters(in: .whitespacesAndNewlines))
        perform { try viewModel.updateSession(session, title: title, focus: focus, plannedDurationMinutes: duration, notes: notes) }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch TrainingPlanEditorError.validationFailed(let issues) {
            errorMessage = issues.map(\.message).joined(separator: "\n")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PlannedExerciseEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let plannedExercise: PlannedExercise
    @State private var name: String
    @State private var muscleGroup: String
    @State private var equipment: String
    @State private var cueing: String
    @State private var tempo: String
    @State private var targetRIR: String
    @State private var painTarget: String
    @State private var notes: String
    @State private var errorMessage: String?

    private var viewModel: TrainingPlanEditorViewModel {
        TrainingPlanEditorViewModel(context: modelContext)
    }

    init(plannedExercise: PlannedExercise) {
        self.plannedExercise = plannedExercise
        _name = State(initialValue: plannedExercise.exercise?.name ?? "")
        _muscleGroup = State(initialValue: plannedExercise.exercise?.muscleGroup ?? "")
        _equipment = State(initialValue: plannedExercise.exercise?.equipment ?? "")
        _cueing = State(initialValue: plannedExercise.cueing ?? "")
        _tempo = State(initialValue: plannedExercise.tempo ?? "")
        _targetRIR = State(initialValue: plannedExercise.targetRIRText ?? "")
        _painTarget = State(initialValue: plannedExercise.painTargetText ?? "")
        _notes = State(initialValue: plannedExercise.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Uebung") {
                TextField("Uebungsname", text: $name)
                TextField("Muskelgruppe", text: $muscleGroup)
                TextField("Equipment", text: $equipment)
                TextField("Cueing", text: $cueing, axis: .vertical)
                    .lineLimit(2...5)
                TextField("Tempo", text: $tempo)
                TextField("Ziel-RIR", text: $targetRIR)
                TextField("Schmerz-Ziel", text: $painTarget)
                TextField("Notizen", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                Button("Uebung sichern") { saveExercise() }
            }

            Section {
                Button {
                    perform { _ = try viewModel.addSet(to: plannedExercise) }
                } label: {
                    Label("Satz hinzufuegen", systemImage: "plus.circle")
                }
            }

            Section("Saetze") {
                ForEach(sets, id: \.id) { set in
                    NavigationLink {
                        PlannedSetEditorView(set: set)
                    } label: {
                        PlanEditorRowTitle(title: "Satz \(set.setNumber): \(set.repsText ?? "-")", subtitle: set.setType.title)
                    }
                    .contextMenu {
                        Button { perform { try viewModel.moveSet(set, in: plannedExercise, direction: .up) } } label: { Label("Nach oben", systemImage: "arrow.up") }
                        Button { perform { try viewModel.moveSet(set, in: plannedExercise, direction: .down) } } label: { Label("Nach unten", systemImage: "arrow.down") }
                        Button { perform { _ = try viewModel.duplicateSet(set, in: plannedExercise) } } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
                        Button(role: .destructive) { perform { try viewModel.deleteSet(set, from: plannedExercise) } } label: { Label("Loeschen", systemImage: "trash") }
                    }
                }
            }
        }
        .navigationTitle("Uebung bearbeiten")
        .alert("Editor-Aktion fehlgeschlagen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var sets: [PlannedSet] {
        plannedExercise.plannedSets.sorted { $0.setNumber < $1.setNumber }
    }

    private func saveExercise() {
        perform {
            try viewModel.updateExercise(
                plannedExercise,
                name: name,
                muscleGroup: muscleGroup,
                equipment: equipment,
                cueing: cueing,
                tempo: tempo,
                targetRIR: targetRIR,
                painTarget: painTarget,
                notes: notes
            )
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch TrainingPlanEditorError.validationFailed(let issues) {
            errorMessage = issues.map(\.message).joined(separator: "\n")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PlannedSetEditorView: View {
    @Environment(\.modelContext) private var modelContext

    let set: PlannedSet
    @State private var reps: String
    @State private var weight: String
    @State private var targetRIR: String
    @State private var rest: String
    @State private var tempo: String
    @State private var setType: PlannedSetType
    @State private var painTarget: String
    @State private var notes: String
    @State private var errorMessage: String?

    private var viewModel: TrainingPlanEditorViewModel {
        TrainingPlanEditorViewModel(context: modelContext)
    }

    init(set: PlannedSet) {
        self.set = set
        _reps = State(initialValue: set.repsText ?? "")
        _weight = State(initialValue: set.weightText ?? "")
        _targetRIR = State(initialValue: set.targetRIRText ?? "")
        _rest = State(initialValue: set.restText ?? "")
        _tempo = State(initialValue: set.tempo ?? "")
        _setType = State(initialValue: set.setType)
        _painTarget = State(initialValue: set.painTargetText ?? "")
        _notes = State(initialValue: set.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Satz") {
                TextField("Geplante Wiederholungen", text: $reps)
                TextField("Geplantes Gewicht", text: $weight)
                TextField("Ziel-RIR", text: $targetRIR)
                TextField("Pause", text: $rest)
                TextField("Tempo", text: $tempo)
                Picker("Satztyp", selection: $setType) {
                    ForEach(PlannedSetType.allCases, id: \.self) { type in
                        Text(type.title).tag(type)
                    }
                }
                TextField("Schmerz-Ziel", text: $painTarget)
                TextField("Notizen", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                Button("Satz sichern") { saveSet() }
            }
        }
        .navigationTitle("Satz bearbeiten")
        .alert("Editor-Aktion fehlgeschlagen", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func saveSet() {
        do {
            try viewModel.updateSet(
                set,
                reps: reps,
                weight: weight,
                targetRIR: targetRIR,
                rest: rest,
                tempo: tempo,
                setType: setType,
                painTarget: painTarget,
                notes: notes
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PlanEditorRowTitle: View {
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.body.weight(.medium))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
