import Combine
import Foundation
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var route: AppRoute = .onboarding
    @Published private(set) var blockingState: BlockingState = .unlocked
    @Published private(set) var isScanning = false
    @Published private(set) var hasRegisteredTag = false
    @Published private(set) var hasCompletedOnboarding = false
    @Published private(set) var lastConfirmation: String?
    @Published var isBetaModeEnabled = false {
        didSet {
            persistence.isBetaModeEnabled = isBetaModeEnabled
            guard oldValue != isBetaModeEnabled else { return }

            if oldValue, !isBetaModeEnabled {
                blockingState = blockingService.isLocked ? .locked : .unlocked
                persistence.blockingState = blockingState
                lastConfirmation = "Real mode ready"
            }
        }
    }
    @Published var errorMessage: String?

    let blockingService: AppBlockingService
    let nfcManager: NFCManaging
    let persistence: PersistenceManaging

    var isShowingError: Bool {
        get { errorMessage != nil }
        set {
            if !newValue {
                errorMessage = nil
            }
        }
    }

    init(
        blockingService: AppBlockingService,
        nfcManager: NFCManaging,
        persistence: PersistenceManaging
    ) {
        self.blockingService = blockingService
        self.nfcManager = nfcManager
        self.persistence = persistence
    }

    func restore() async {
        hasCompletedOnboarding = persistence.hasCompletedOnboarding
        hasRegisteredTag = persistence.registeredTagID != nil
        isBetaModeEnabled = persistence.isBetaModeEnabled

        let persistedState = persistence.blockingState
        blockingState = isBetaModeEnabled ? persistedState : blockingService.isLocked ? .locked : persistedState

        if !isBetaModeEnabled, blockingState == .locked, !blockingService.isLocked {
            do {
                try await blockingService.lock()
            } catch {
                blockingState = .unlocked
                persistence.blockingState = .unlocked
            }
        }

        route = hasCompletedOnboarding ? .home : .onboarding
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        persistence.hasCompletedOnboarding = true
        route = .home
    }

    func requestAuthorization() async {
        guard !isBetaModeEnabled else {
            lastConfirmation = "Beta mode ready"
            return
        }

        do {
            try await blockingService.requestAuthorization()
        } catch {
            show(.authorizationDenied)
        }
    }

    func registerTag() async {
        if isBetaModeEnabled {
            persistence.registeredTagID = "beta-mode-tag"
            hasRegisteredTag = true
            lastConfirmation = "Beta key connected"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        await performScan(prompt: "Hold your iPhone near the NFC tag.") { [weak self] tag in
            self?.persistence.registeredTagID = tag.id
            self?.hasRegisteredTag = true
            self?.lastConfirmation = "Tag connected"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func handleTagTap() async {
        guard hasRegisteredTag else {
            show(.noRegisteredTag)
            return
        }

        if isBetaModeEnabled {
            await toggleBetaBlockingState()
            return
        }

        await performScan(prompt: "Tap your key.") { [weak self] tag in
            guard let self else { return }
            guard nfcManager.isRegisteredTag(tag, registeredID: persistence.registeredTagID) else {
                show(.unknownTag)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                return
            }

            do {
                switch blockingState {
                case .unlocked:
                    try await blockingService.lock()
                    blockingState = .locked
                    persistence.blockingState = .locked
                    lastConfirmation = "Locked"
                case .locked:
                    try await blockingService.unlock()
                    blockingState = .unlocked
                    persistence.blockingState = .unlocked
                    lastConfirmation = "Unlocked"
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                show(.blockingFailed)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    func unlockWithoutNFCForRecovery() async {
        do {
            if !isBetaModeEnabled {
                try await blockingService.unlock()
            }
            blockingState = .unlocked
            persistence.blockingState = .unlocked
            lastConfirmation = "Unlocked"
        } catch {
            show(.blockingFailed)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func performScan(
        prompt: String,
        onSuccess: @escaping (NFCTagIdentity) async -> Void
    ) async {
        guard nfcManager.isAvailable else {
            show(.nfcUnavailable)
            return
        }

        isScanning = true
        defer { isScanning = false }

        do {
            let tag = try await nfcManager.scanTag(prompt: prompt)
            await onSuccess(tag)
        } catch let appError as AppError {
            if appError != .nfcCancelled {
                show(appError)
            }
        } catch {
            show(.tagReadFailed)
        }
    }

    private func show(_ error: AppError) {
        errorMessage = error.errorDescription
    }

    private func toggleBetaBlockingState() async {
        isScanning = true
        defer { isScanning = false }

        try? await Task.sleep(nanoseconds: 650_000_000)

        switch blockingState {
        case .unlocked:
            blockingState = .locked
            persistence.blockingState = .locked
            lastConfirmation = "Locked"
        case .locked:
            blockingState = .unlocked
            persistence.blockingState = .unlocked
            lastConfirmation = "Unlocked"
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
