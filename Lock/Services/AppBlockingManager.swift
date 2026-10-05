import FamilyControls
import Foundation
import ManagedSettings

protocol AppBlockingService: AnyObject {
    var isLocked: Bool { get }
    var selection: FamilyActivitySelection { get set }
    func requestAuthorization() async throws
    func lock() async throws
    func unlock() async throws
}

final class AppBlockingManager: AppBlockingService {
    private let store = ManagedSettingsStore()
    private let selectionStore = UserDefaults.standard
    private let selectionKey = "lock.familyActivitySelection"

    var selection: FamilyActivitySelection {
        get {
            guard let data = selectionStore.data(forKey: selectionKey),
                  let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
                return FamilyActivitySelection()
            }

            return selection
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            selectionStore.set(data, forKey: selectionKey)
        }
    }

    var isLocked: Bool {
        store.shield.applications != nil || store.shield.applicationCategories != nil
    }

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
    }

    func lock() async throws {
        let currentSelection = selection
        store.shield.applications = currentSelection.applicationTokens.isEmpty ? nil : currentSelection.applicationTokens
        store.shield.applicationCategories = currentSelection.categoryTokens.isEmpty ? nil : .specific(currentSelection.categoryTokens)
        store.shield.webDomains = currentSelection.webDomainTokens.isEmpty ? nil : currentSelection.webDomainTokens
    }

    func unlock() async throws {
        store.clearAllSettings()
    }
}
