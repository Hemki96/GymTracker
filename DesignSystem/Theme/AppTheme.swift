import Foundation
import SwiftUI

enum AppTheme {
    enum Spacing {
        static let screen: CGFloat = 24
        static let large: CGFloat = 16
    }
}

extension View {
    @ViewBuilder
    func appGroupedBackground() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self
        } else {
            background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    func appCardSurface(fallbackColor: Color = Color(.secondarySystemGroupedBackground)) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(fallbackColor)
            }
        }
    }

    @ViewBuilder
    func appTintedCardSurface(_ color: Color) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular.tint(color.opacity(0.18)), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
            glassEffect(.regular.tint(color.opacity(0.18)).interactive(), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.16))
            }
        }
    }

    @ViewBuilder
    func appControlSurface(fallbackColor: Color = Color(.tertiarySystemGroupedBackground)) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
