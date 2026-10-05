import FamilyControls
import Foundation

#if DEBUG
final class MockNFCManager: NFCManaging {
    var isAvailable = true
    var nextResult: Result<NFCTagIdentity, Error> = .success(NFCTagIdentity(id: "mock-tag"))

    func scanTag(prompt: String) async throws -> NFCTagIdentity {
        try nextResult.get()
    }

    func isRegisteredTag(_ tag: NFCTagIdentity, registeredID: String?) -> Bool {
        tag.id == registeredID
    }
}

final class MockAppBlockingManager: AppBlockingService {
    var isLocked = false
    var shouldFail = false
    var selection = FamilyActivitySelection()

    func requestAuthorization() async throws {
        if shouldFail { throw AppError.authorizationDenied }
    }

    func lock() async throws {
        if shouldFail { throw AppError.blockingFailed }
        isLocked = true
    }

    func unlock() async throws {
        if shouldFail { throw AppError.blockingFailed }
        isLocked = false
    }
}

final class InMemoryPersistenceManager: PersistenceManaging {
    var hasCompletedOnboarding = false
    var registeredTagID: String?
    var blockingState: BlockingState = .unlocked
    var isBetaModeEnabled = false
}
#endif
