import SwiftUI

struct NFCAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 136, height: 92)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                }
                .shadow(color: Color.black.opacity(0.08), radius: 22, y: 12)

            Image(systemName: "wave.3.right")
                .font(.system(size: 34, weight: .semibold))
                .offset(x: pulse && !reduceMotion ? 24 : 12)
                .opacity(pulse && !reduceMotion ? 0.2 : 0.85)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                    value: pulse
                )
        }
        .onAppear { pulse = true }
        .accessibilityHidden(true)
    }
}
