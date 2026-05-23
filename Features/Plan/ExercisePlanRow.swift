import SwiftData
import SwiftUI

struct ExercisePlanRow: View {
    let plannedExercise: PlannedExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(plannedExercise.sortOrder)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .appCircularControlSurface()

                VStack(alignment: .leading, spacing: 4) {
                    Text(plannedExercise.exercise?.name ?? "Unbekannte Übung")
                        .font(.headline)

                    let details = [plannedExercise.exercise?.muscleGroup, plannedExercise.exercise?.equipment]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                        .joined(separator: " · ")
                    if !details.isEmpty {
                        Text(details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let notes = plannedExercise.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 8)], alignment: .leading, spacing: 8) {
                PlanValuePill(title: "Sätze", value: plannedExercise.setsPrescription)
                PlanValuePill(title: "Wdh.", value: plannedExercise.repsPrescription)
                PlanValuePill(title: "Gewicht", value: plannedExercise.plannedWeightText)
                PlanValuePill(title: "Ziel-RIR", value: plannedExercise.targetRIRText)
                PlanValuePill(title: "Schmerz", value: plannedExercise.painTargetText)
                PlanValuePill(title: "Tempo", value: plannedExercise.tempo)
            }

            if let cueing = plannedExercise.cueing, !cueing.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cueing")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(cueing)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }

            if !sets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saetze")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(sets, id: \.id) { set in
                        HStack(spacing: 8) {
                            Text("\(set.setNumber)")
                                .font(.caption.weight(.bold))
                                .frame(width: 24, height: 24)
                                .appCircularControlSurface()
                            Text(setSummary(set))
                                .font(.caption)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }

    private var sets: [PlannedSet] {
        plannedExercise.plannedSets.sorted { $0.setNumber < $1.setNumber }
    }

    private func setSummary(_ set: PlannedSet) -> String {
        [
            set.setType.title,
            set.repsText,
            set.weightText,
            set.targetRIRText.map { "RIR \($0)" },
            set.restText.map { "Pause \($0)" },
            set.tempo.map { "Tempo \($0)" }
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: " · ")
    }
}

private struct PlanValuePill: View {
    let title: String
    let value: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(displayValue)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .appControlSurface()
    }

    private var displayValue: String {
        guard let value, !value.isEmpty else {
            return "-"
        }

        return value
    }
}

#Preview {
    let context = ModelContext(PlanPreviewData.container)
    let exercises = (try? context.fetch(FetchDescriptor<PlannedExercise>())) ?? []
    let exercise = exercises.first { $0.sortOrder == 1 } ?? exercises[0]

    ExercisePlanRow(plannedExercise: exercise)
        .padding()
        .appGroupedBackground()
}
