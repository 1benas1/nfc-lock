import Foundation

protocol PersistenceManaging: AnyObject {
    var hasCompletedOnboarding: Bool { get set }
    var registeredTagID: String? { get set }
    var blockingState: BlockingState { get set }
    var isBetaModeEnabled: Bool { get set }
}

final class UserDefaultsPersistenceManager: PersistenceManaging {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "lock.hasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "lock.hasCompletedOnboarding") }
    }

    var registeredTagID: String? {
        get { defaults.string(forKey: "lock.registeredTagID") }
        set { defaults.set(newValue, forKey: "lock.registeredTagID") }
    }

    var blockingState: BlockingState {
        get {
            guard let rawValue = defaults.string(forKey: "lock.blockingState") else {
                return .unlocked
            }

            return BlockingState(rawValue: rawValue) ?? .unlocked
        }
        set {
            defaults.set(newValue.rawValue, forKey: "lock.blockingState")
        }
    }

    var isBetaModeEnabled: Bool {
        get { defaults.bool(forKey: "lock.isBetaModeEnabled") }
        set { defaults.set(newValue, forKey: "lock.isBetaModeEnabled") }
    }
}
