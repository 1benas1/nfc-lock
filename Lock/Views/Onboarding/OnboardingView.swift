import FamilyControls
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var step = 0
    @State private var selectionDraft = FamilyActivitySelection()

    var body: some View {
        VStack {
            TabView(selection: $step) {
                WelcomeStep {
                    withAnimation { step = 1 }
                }
                .tag(0)

                AppSelectionStep(selection: $selectionDraft) {
                    model.blockingService.selection = selectionDraft
                    Task {
                        await model.requestAuthorization()
                        withAnimation { step = 2 }
                    }
                }
                .tag(1)

                NFCSetupStep {
                    Task {
                        await model.registerTag()
                        model.completeOnboarding()
                    }
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onAppear {
                selectionDraft = model.blockingService.selection
            }

            StepDots(count: 3, current: step)
                .padding(.bottom, 18)
        }
    }
}

private struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingShell {
            Spacer(minLength: 28)
            PhoneAndTagIllustration()
            Spacer(minLength: 48)
            StepHeader(
                title: "Put your phone down.",
                subtitle: "Lock distracting apps with one physical tap."
            )
            Spacer()
            PrimaryButton(title: "Get started", systemImage: "arrow.right", action: onContinue)
        }
    }
}

private struct AppSelectionStep: View {
    @EnvironmentObject private var model: AppModel
    @Binding var selection: FamilyActivitySelection
    let onContinue: () -> Void
    @State private var isPickerPresented = false

    var body: some View {
        OnboardingShell {
            Spacer(minLength: 36)
            StepHeader(
                title: "Choose the apps.",
                subtitle: model.isBetaModeEnabled ? "Beta mode skips real blocking." : "Pick what Lock should block."
            )

            Button {
                isPickerPresented = true
            } label: {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.08))
                            .frame(width: 78, height: 78)
                        Image(systemName: selectionCount == 0 ? "plus.app" : "checkmark.seal.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                    }

                    VStack(spacing: 5) {
                        Text(selectionSummary)
                            .font(.system(size: 25, weight: .semibold, design: .rounded))
                        Text(model.isBetaModeEnabled ? "You can continue without choosing apps." : "Tap here, then choose them.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 228)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                }
                .shadow(color: Color.black.opacity(0.05), radius: 18, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.top, 34)
            .disabled(model.isBetaModeEnabled)
            .opacity(model.isBetaModeEnabled ? 0.45 : 1)
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)

            Toggle(isOn: $model.isBetaModeEnabled) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Beta mode")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Practice first. Nothing gets blocked.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding(16)
            .background(Color(.secondarySystemBackground).opacity(0.6), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.top, 18)

            Spacer()
            PrimaryButton(title: "Continue", systemImage: "arrow.right", action: onContinue)
        }
    }

    private var selectionCount: Int {
        selection.applicationTokens.count + selection.categoryTokens.count + selection.webDomainTokens.count
    }

    private var selectionSummary: String {
        selectionCount == 0 ? "Select apps" : "\(selectionCount) selected"
    }
}

private struct NFCSetupStep: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingShell {
            Spacer(minLength: 46)
            NFCAnimation()
                .scaleEffect(1.18)
            Spacer(minLength: 58)
            StepHeader(
                title: "Make the tag your key.",
                subtitle: "Tap it once to connect. Use the same tag to lock and unlock."
            )
            Spacer()
            PrimaryButton(title: "Connect your key", systemImage: "wave.3.right", action: onContinue)
        }
    }
}

private struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .lineSpacing(2)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.82)

            Text(subtitle)
                .font(.system(size: 22, weight: .regular, design: .rounded))
                .lineSpacing(4)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.86)
                .padding(.horizontal, 8)
        }
    }
}

private struct OnboardingShell<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 30)
    }
}

private struct StepDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.primary : Color.primary.opacity(0.18))
                    .frame(width: index == current ? 26 : 8, height: 8)
            }
        }
        .animation(.smooth, value: current)
    }
}

private struct PhoneAndTagIllustration: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 166, height: 250)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(Color.primary.opacity(0.18))
                        .frame(width: 52, height: 5)
                        .padding(.top, 13)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08))
                }
                .shadow(color: Color.black.opacity(0.08), radius: 18, y: 10)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.systemBackground))
                .frame(width: 108, height: 76)
                .overlay {
                    Image(systemName: "wave.3.right")
                        .font(.system(size: 29, weight: .semibold))
                }
                .shadow(color: Color.black.opacity(0.12), radius: 18, y: 10)
                .offset(x: 40, y: 16)
        }
        .accessibilityHidden(true)
    }
}
