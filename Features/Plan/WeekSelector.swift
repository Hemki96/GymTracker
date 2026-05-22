import SwiftData
import SwiftUI

struct WeekSelector: View {
    let weeks: [TrainingWeek]
    @Binding var selectedWeekNumber: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(weeks, id: \.id) { week in
                    Button {
                        selectedWeekNumber = week.weekNumber
                    } label: {
                        VStack(spacing: 4) {
                            Text("Woche")
                                .font(.caption2.weight(.medium))
                            Text("\(week.weekNumber)")
                                .font(.headline.weight(.semibold))
                        }
                        .frame(width: 72, height: 56)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(selectedWeekNumber == week.weekNumber ? .white : .primary)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedWeekNumber == week.weekNumber ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                    }
                    .accessibilityLabel("Woche \(week.weekNumber)")
                    .accessibilityValue(selectedWeekNumber == week.weekNumber ? "Ausgewählt" : "")
                }
            }
            .padding(.horizontal, AppTheme.Spacing.screen)
        }
    }
}

#Preview {
    let context = ModelContext(PlanPreviewData.container)
    let weeks = (try? context.fetch(FetchDescriptor<TrainingWeek>(sortBy: [SortDescriptor(\.weekNumber)]))) ?? []

    WeekSelector(weeks: weeks, selectedWeekNumber: .constant(1))
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
}
