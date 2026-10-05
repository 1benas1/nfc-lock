import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isDisabled = false
    var style: Style = .primary
    let action: () -> Void

    enum Style {
        case primary
        case secondary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .foregroundStyle(foregroundStyle)
            .background(backgroundStyle, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(borderStyle, lineWidth: style == .primary ? 0 : 1)
            }
            .shadow(color: shadowColor, radius: style == .primary ? 18 : 0, y: style == .primary ? 10 : 0)
            .opacity(isDisabled ? 0.35 : 1)
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isDisabled)
        .accessibilityLabel(title)
    }

    private var foregroundStyle: Color {
        style == .primary ? Color(.systemBackground) : Color.primary
    }

    private var backgroundStyle: Color {
        style == .primary ? Color.primary : Color(.secondarySystemBackground)
    }

    private var borderStyle: Color {
        Color.primary.opacity(0.08)
    }

    private var shadowColor: Color {
        Color.black.opacity(0.12)
    }
}

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!reduceMotion && configuration.isPressed ? 0.96 : 1)
            .animation(reduceMotion ? nil : .smooth(duration: 0.16), value: configuration.isPressed)
    }
}
