import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query(
        filter: #Predicate<SessionLog> { session in
            session.statusRaw == "completed"
        },
        sort: \SessionLog.completedAt,
        order: .reverse
    ) private var completedSessions: [SessionLog]

    var body: some View {
        NavigationStack {
            Group {
                if completedSessions.isEmpty {
                    ContentUnavailableView(
                        "Keine Historie",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Abgeschlossene Sessions erscheinen hier.")
                    )
                } else {
                    List(completedSessions, id: \.id) { session in
                        NavigationLink {
                            SessionSummaryView(sessionLog: session)
                        } label: {
                            HistorySessionRow(sessionLog: session)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Historie")
        }
    }
}

private struct HistorySessionRow: View {
    let sessionLog: SessionLog

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(sessionLog.workoutPlan?.title ?? "Training")
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(dateText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label(durationText, systemImage: "clock")
                Label(volumeText, systemImage: "scalemass")
                Label(warningText, systemImage: "exclamationmark.triangle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var dateText: String {
        (sessionLog.completedAt ?? sessionLog.startedAt).formatted(date: .abbreviated, time: .shortened)
    }

    private var durationText: String {
        guard let durationSeconds = sessionLog.durationSeconds else { return "-" }
        return "\(max(durationSeconds / 60, 1)) min"
    }

    private var volumeText: String {
        guard let totalVolumeKg = sessionLog.totalVolumeKg else { return "-" }
        return "\(totalVolumeKg.formatted(.number.precision(.fractionLength(0...0)))) kg"
    }

    private var warningText: String {
        "\(sessionLog.warningMessages.count)"
    }
}

#if DEBUG
#Preview {
    HistoryView()
        .modelContainer(PlanPreviewData.container)
}
#endif
