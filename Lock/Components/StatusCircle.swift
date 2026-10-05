import SwiftUI

struct StatusCircle: View {
    let state: BlockingState
    let isScanning: Bool
    var hasKey = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var label: String {
        if !hasKey {
            return "No key"
        }
        return state == .locked ? "Locked" : "Unlocked"
    }

    private var iconName: String {
        if !hasKey {
            return "key.fill"
        }
        return state == .locked ? "lock.fill" : "lock.open.fill"
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.1), radius: 34, y: 18)

            Circle()
                .fill(state == .locked && hasKey ? Color.primary.opacity(0.08) : Color(.systemBackground))
                .padding(20)

            Circle()
                .trim(from: 0.08, to: isScanning && !reduceMotion ? 0.9 : 0.76)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(isScanning && !reduceMotion ? 360 : -60))
                .padding(14)
                .animation(ringAnimation, value: isScanning)

            VStack(spacing: 18) {
                Image(systemName: iconName)
                    .font(.system(size: 46, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .contentTransition(.symbolEffect(.replace))

                Text(label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
        }
        .frame(width: 286, height: 286)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var ringColor: Color {
        if !hasKey {
            return Color.primary.opacity(0.22)
        }
        return state == .locked ? Color.primary.opacity(0.84) : Color.primary.opacity(0.28)
    }

    private var ringAnimation: Animation? {
        guard !reduceMotion else { return .smooth }
        return isScanning ? .linear(duration: 1.4).repeatForever(autoreverses: false) : .smooth
    }

    private var accessibilityText: String {
        if isScanning {
            return "Hold your iPhone near the key"
        }
        return label
    }
}
