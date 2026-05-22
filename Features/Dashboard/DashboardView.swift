import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                Text(viewModel.title)
                    .font(.largeTitle.bold())

                Text(viewModel.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.screen)
            .navigationTitle(viewModel.title)
        }
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel(summary: .empty))
}
