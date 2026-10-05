import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ZStack {
            BackgroundView()

            switch model.route {
            case .onboarding:
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            case .home, .setup:
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.35), value: model.route)
        .task {
            await model.restore()
        }
        .alert("Try that again", isPresented: $model.isShowingError) {
            Button("OK", role: .cancel) { model.clearError() }
        } message: {
            Text(model.errorMessage ?? "Please try again.")
        }
    }
}

private struct BackgroundView: View {
    var body: some View {
        Color(.systemBackground)
            .overlay {
                GeometryReader { proxy in
                    Circle()
                        .fill(Color.primary.opacity(0.035))
                        .frame(width: proxy.size.width * 0.8)
                        .offset(x: proxy.size.width * 0.42, y: -proxy.size.height * 0.2)
                        .blur(radius: 28)
                }
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
    }
}
