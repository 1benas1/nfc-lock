import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isSettingsPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Lock")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Spacer()
                    if model.isBetaModeEnabled {
                        Text("Beta")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Color.primary.opacity(0.08), in: Capsule())
                            .accessibilityLabel("Beta mode is on")
                    }
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22, weight: .medium))
                            .frame(width: 52, height: 52)
                            .background(Color(.secondarySystemBackground), in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer(minLength: 22)

                StatusCircle(
                    state: model.blockingState,
                    isScanning: model.isScanning,
                    hasKey: model.hasRegisteredTag
                )
                .padding(.bottom, 34)

                VStack(spacing: 10) {
                    Text(headline)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .contentTransition(.numericText())

                    Text(subtitle)
                        .font(.system(size: 22, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.86)
                }
                .padding(.horizontal, 28)
                .animation(.smooth(duration: 0.25), value: headline)

                if let confirmation = confirmationText {
                    Text(confirmation)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.top, 16)
                        .transition(.opacity)
                }

                Spacer(minLength: 34)

                PrimaryButton(
                    title: primaryActionTitle,
                    systemImage: primaryActionIcon,
                    isDisabled: model.isScanning
                ) {
                    if model.hasRegisteredTag {
                        Task { await model.handleTagTap() }
                    } else {
                        Task { await model.registerTag() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
    }

    private var headline: String {
        if model.isScanning {
            return "Hold it near."
        }
        if !model.hasRegisteredTag {
            return "Connect your key."
        }
        return model.blockingState == .locked ? "You’re locked in." : "You’re unlocked."
    }

    private var subtitle: String {
        if model.isScanning {
            return "Keep your iPhone on the key."
        }
        if !model.hasRegisteredTag {
            return "One tap connects it. The same key locks and unlocks."
        }
        return model.blockingState == .locked ? "Distracting apps are blocked." : "Your apps are available."
    }

    private var primaryActionTitle: String {
        if model.isScanning {
            return "Hold near key"
        }
        if !model.hasRegisteredTag {
            return "Connect your key"
        }
        return model.blockingState == .locked ? "Tap key to unlock" : "Tap key to lock"
    }

    private var primaryActionIcon: String? {
        if model.isScanning {
            return nil
        }
        return model.hasRegisteredTag ? "wave.3.right" : "key"
    }

    private var confirmationText: String? {
        switch model.lastConfirmation {
        case "Locked":
            return "See you later."
        case "Unlocked":
            return "You’re back."
        case "Tag connected", "Beta key connected":
            return "Your key is ready."
        case "Real mode ready":
            return "Real blocking is on."
        case "Beta mode ready":
            return "Beta mode is on."
        default:
            return nil
        }
    }
}
