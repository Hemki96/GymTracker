import Foundation
import SwiftUI

// MARK: - Design Tokens

// AppTheme is the single place for spacing, radius, and surface decisions. The
// feature views should compose these tokens instead of inventing per-screen
// shadows or backgrounds, which keeps the iOS 26 glass fallback strategy aligned.
enum AppTheme {
    enum ColorToken {
        static let primary = Color.accentColor
        static let secondary = Color(.secondaryLabel)
        static let surface = Color(.secondarySystemGroupedBackground)
        static let elevatedSurface = Color(.tertiarySystemGroupedBackground)
        static let background = Color(.systemGroupedBackground)
        static let error = Color.red
        static let success = Color.green
        static let warning = Color.orange
    }

    enum Spacing {
        static let xsmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let screen: CGFloat = 24
        static let xlarge: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 8
        static let control: CGFloat = 8
    }

    enum Animation {
        static let subtle = SwiftUI.Animation.snappy(duration: 0.22)
    }
}

// MARK: - Surface Modifiers

extension View {
    func appScreenPadding() -> some View {
        padding(AppTheme.Spacing.screen)
    }

    @ViewBuilder
    func appGroupedBackground() -> some View {
        // Liquid Glass provides its own depth and background behavior on modern
        // OS releases; older systems receive an explicit grouped background.
        if #available(iOS 26.0, macOS 26.0, *) {
            self
        } else {
            background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    func appCardSurface(fallbackColor: Color = Color(.secondarySystemGroupedBackground)) -> some View {
        // Every card-like surface goes through this modifier so glass adoption
        // remains a theme-level choice instead of scattered availability checks.
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .fill(fallbackColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
            }
        }
    }

    @ViewBuilder
    func appTintedCardSurface(_ color: Color) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular.tint(color.opacity(0.18)), in: RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                    .fill(color.opacity(0.12))
            }
        }
    }

    @ViewBuilder
    func appSetLogSurface(isCompleted: Bool) -> some View {
        if isCompleted {
            appTintedCardSurface(.green)
        } else {
            appCardSurface()
        }
    }

    @ViewBuilder
    func appPainControlSurface(_ color: Color) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular.tint(color.opacity(0.18)).interactive(), in: RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(color.opacity(0.16))
            }
        }
    }

    @ViewBuilder
    func appControlSurface(fallbackColor: Color = Color(.tertiarySystemGroupedBackground)) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(fallbackColor)
            }
        }
    }

    @ViewBuilder
    func appCircularControlSurface(fallbackColor: Color = Color(.tertiarySystemGroupedBackground)) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Circle())
        } else {
            background {
                Circle()
                    .fill(fallbackColor)
            }
        }
    }

    @ViewBuilder
    func appFloatingBarSurface() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular, in: Rectangle())
        } else {
            background(.regularMaterial)
        }
    }
}

struct AppCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(padding: CGFloat = AppTheme.Spacing.large, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCardSurface()
    }
}

struct SectionContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String?
    @ViewBuilder let content: Content

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                    Text(title)
                        .font(.headline)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(AppPrimaryButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(AppSecondaryButtonStyle())
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .background {
                RoundedRectangle(cornerRadius: AppTheme.Radius.control, style: .continuous)
                    .fill(AppTheme.ColorToken.primary)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppTheme.Animation.subtle, value: configuration.isPressed)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .appControlSurface()
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppTheme.Animation.subtle, value: configuration.isPressed)
    }
}

struct LoadingView: View {
    let title: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            ProgressView()
                .controlSize(.large)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .frame(maxWidth: .infinity, minHeight: 280)
    }
}

struct ErrorStateView: View {
    let title: String
    let message: String

    var body: some View {
        AppCard {
            Label(title, systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.ColorToken.error)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, AppTheme.Spacing.xsmall)
        }
        .appTintedCardSurface(AppTheme.ColorToken.error)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = AppTheme.ColorToken.primary

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .appTintedCardSurface(tint)

                Text(value)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                    Image(systemName: systemImage)
                        .foregroundStyle(AppTheme.ColorToken.primary)
                        .frame(width: 28, height: 28)
                        .appTintedCardSurface(AppTheme.ColorToken.primary)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                        Text(title)
                            .font(.headline)
                        if let subtitle {
                            Text(subtitle)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: AppTheme.Spacing.small)
                }

                content
            }
        }
    }
}

struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text, axis: axis)
                .lineLimit(axis == .vertical ? 2...5 : 1...1)
                .frame(minHeight: 48)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .appControlSurface()
                .accessibilityLabel(title)
        }
    }
}

struct ModernNavigationBar: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.ColorToken.primary)
            }

            Text(title)
                .font(.largeTitle.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct AppStatusPill: View {
    let title: String
    let systemImage: String?
    var tint: Color = AppTheme.ColorToken.primary

    var body: some View {
        Label {
            Text(title)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint)
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}
