import Charts
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    @Query(
        filter: #Predicate<SessionLog> { session in
            session.statusRaw == "completed"
        },
        sort: \SessionLog.completedAt,
        order: .forward
    ) private var completedSessions: [SessionLog]

    @State private var selectedExerciseID: UUID?

    private let mapper = ChartDataMapper()

    private var weeklyVolume: [WeeklyVolumePoint] {
        mapper.weeklyVolume(from: completedSessions)
    }

    private var painTrend: [MetricTrendPoint] {
        mapper.painTrend(from: completedSessions)
    }

    private var rirTrend: [MetricTrendPoint] {
        mapper.rirTrend(from: completedSessions)
    }

    private var exerciseOptions: [ExerciseFilterOption] {
        mapper.exerciseOptions(from: completedSessions)
    }

    private var weightTrend: [ExerciseWeightPoint] {
        mapper.weightTrend(for: selectedExerciseID, in: completedSessions)
    }

    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    ContentUnavailableView(
                        "Keine Analysedaten",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Schließe Sessions ab, um Volumen, Schmerz, RIR und Gewichte auszuwerten.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                            weeklyVolumeChart
                            painChart
                            rirChart
                            weightChart
                        }
                        .padding(AppTheme.Spacing.screen)
                    }
                    .appGroupedBackground()
                }
            }
            .navigationTitle("Analyse")
            .onAppear(perform: selectDefaultExerciseIfNeeded)
            .onChange(of: exerciseOptions) { _, _ in
                selectDefaultExerciseIfNeeded()
            }
        }
    }

    private var weeklyVolumeChart: some View {
        AnalyticsChartCard(
            title: "Wochenvolumen",
            subtitle: "Gesamtes Trainingsvolumen pro Kalenderwoche",
            isEmpty: weeklyVolume.isEmpty,
            emptyTitle: "Noch kein Volumen",
            emptyMessage: "Erfasste Arbeitssätze mit Gewicht erscheinen hier."
        ) {
            Chart(weeklyVolume) { point in
                BarMark(
                    x: .value("Woche", point.weekStart, unit: .weekOfYear),
                    y: .value("Volumen", point.totalVolumeKg)
                )
                .foregroundStyle(.blue)
                .annotation(position: .top) {
                    if point.totalVolumeKg > 0 {
                        Text(AnalyticsFormatters.kilograms(point.totalVolumeKg))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxisLabel("kg")
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
        }
    }

    private var painChart: some View {
        AnalyticsChartCard(
            title: "Schmerzverlauf",
            subtitle: "Maximaler Schmerz je abgeschlossener Session",
            isEmpty: painTrend.isEmpty,
            emptyTitle: "Keine Schmerzwerte",
            emptyMessage: "Sobald Sätze mit Schmerzangaben abgeschlossen sind, entsteht hier der Verlauf."
        ) {
            Chart(painTrend) { point in
                LineMark(
                    x: .value("Datum", point.date),
                    y: .value("Schmerz", point.value)
                )
                .foregroundStyle(.red)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Datum", point.date),
                    y: .value("Schmerz", point.value)
                )
                .foregroundStyle(.red)
            }
            .chartYScale(domain: 0...10)
            .chartYAxisLabel("0-10")
        }
    }

    private var rirChart: some View {
        AnalyticsChartCard(
            title: "RIR-Verlauf",
            subtitle: "Durchschnittliche RIR je abgeschlossener Session",
            isEmpty: rirTrend.isEmpty,
            emptyTitle: "Keine RIR-Werte",
            emptyMessage: "Erfasste RIR-Werte aus abgeschlossenen Sätzen erscheinen hier."
        ) {
            Chart(rirTrend) { point in
                LineMark(
                    x: .value("Datum", point.date),
                    y: .value("RIR", point.value)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Datum", point.date),
                    y: .value("RIR", point.value)
                )
                .foregroundStyle(.green)
            }
            .chartYAxisLabel("RIR")
        }
    }

    private var weightChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExerciseFilter(options: exerciseOptions, selection: $selectedExerciseID)

            AnalyticsChartCard(
                title: "Gewichtsentwicklung",
                subtitle: "Höchstes Arbeitsgewicht pro Session und Übung",
                isEmpty: weightTrend.isEmpty,
                emptyTitle: "Keine Gewichtsdaten",
                emptyMessage: exerciseOptions.isEmpty
                    ? "Abgeschlossene Übungen mit Gewicht erscheinen hier."
                    : "Für diese Übung gibt es noch keine abgeschlossenen Arbeitssätze mit Gewicht."
            ) {
                Chart(weightTrend) { point in
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("Gewicht", point.maxWeightKg)
                    )
                    .foregroundStyle(.purple)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Datum", point.date),
                        y: .value("Gewicht", point.maxWeightKg)
                    )
                    .foregroundStyle(.purple)
                }
                .chartYAxisLabel("kg")
            }
        }
    }

    private func selectDefaultExerciseIfNeeded() {
        guard !exerciseOptions.isEmpty else {
            selectedExerciseID = nil
            return
        }

        if let selectedExerciseID, exerciseOptions.contains(where: { $0.id == selectedExerciseID }) {
            return
        }

        selectedExerciseID = exerciseOptions.first?.id
    }
}

struct ExerciseFilter: View {
    let options: [ExerciseFilterOption]
    @Binding var selection: UUID?

    var body: some View {
        Picker("Übung", selection: $selection) {
            if options.isEmpty {
                Text("Keine Übungen").tag(UUID?.none)
            } else {
                ForEach(options) { option in
                    Text(option.name).tag(Optional(option.id))
                }
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
        .disabled(options.isEmpty)
    }
}

private struct AnalyticsChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let isEmpty: Bool
    let emptyTitle: String
    let emptyMessage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text(emptyMessage)
                )
                .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                content
                    .frame(height: 240)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
            }
        }
        .padding(AppTheme.Spacing.large)
        .appCardSurface()
    }
}

private enum AnalyticsFormatters {
    static func kilograms(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...0)))) kg"
    }
}

#if DEBUG
#Preview {
    AnalyticsView()
        .modelContainer(PlanPreviewData.container)
}
#endif
