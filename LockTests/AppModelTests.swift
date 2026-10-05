import XCTest
@testable import Lock

@MainActor
final class AppModelTests: XCTestCase {
    func testOnboardingCompletionPersistsAndRoutesHome() {
        let persistence = InMemoryPersistenceManager()
        let model = makeModel(persistence: persistence)

        model.completeOnboarding()

        XCTAssertTrue(model.hasCompletedOnboarding)
        XCTAssertTrue(persistence.hasCompletedOnboarding)
        XCTAssertEqual(model.route, .home)
    }

    func testRegisterTagPersistsTagIdentifier() async {
        let nfc = MockNFCManager()
        nfc.nextResult = .success(NFCTagIdentity(id: "tag-1"))
        let persistence = InMemoryPersistenceManager()
        let model = makeModel(nfc: nfc, persistence: persistence)

        await model.registerTag()

        XCTAssertTrue(model.hasRegisteredTag)
        XCTAssertEqual(persistence.registeredTagID, "tag-1")
    }

    func testValidTagLocksWhenUnlocked() async {
        let nfc = MockNFCManager()
        nfc.nextResult = .success(NFCTagIdentity(id: "tag-1"))
        let blocking = MockAppBlockingManager()
        let persistence = InMemoryPersistenceManager()
        persistence.registeredTagID = "tag-1"
        let model = makeModel(blocking: blocking, nfc: nfc, persistence: persistence)

        await model.restore()
        await model.handleTagTap()

        XCTAssertTrue(blocking.isLocked)
        XCTAssertEqual(model.blockingState, .locked)
        XCTAssertEqual(persistence.blockingState, .locked)
    }

    func testValidTagUnlocksWhenLocked() async {
        let nfc = MockNFCManager()
        nfc.nextResult = .success(NFCTagIdentity(id: "tag-1"))
        let blocking = MockAppBlockingManager()
        blocking.isLocked = true
        let persistence = InMemoryPersistenceManager()
        persistence.registeredTagID = "tag-1"
        persistence.blockingState = .locked
        let model = makeModel(blocking: blocking, nfc: nfc, persistence: persistence)

        await model.restore()
        await model.handleTagTap()

        XCTAssertFalse(blocking.isLocked)
        XCTAssertEqual(model.blockingState, .unlocked)
        XCTAssertEqual(persistence.blockingState, .unlocked)
    }

    func testInvalidTagDoesNotLock() async {
        let nfc = MockNFCManager()
        nfc.nextResult = .success(NFCTagIdentity(id: "other-tag"))
        let blocking = MockAppBlockingManager()
        let persistence = InMemoryPersistenceManager()
        persistence.registeredTagID = "tag-1"
        let model = makeModel(blocking: blocking, nfc: nfc, persistence: persistence)

        await model.restore()
        await model.handleTagTap()

        XCTAssertFalse(blocking.isLocked)
        XCTAssertEqual(model.blockingState, .unlocked)
        XCTAssertEqual(model.errorMessage, AppError.unknownTag.errorDescription)
    }

    func testBlockingFailureDoesNotPersistLockedState() async {
        let nfc = MockNFCManager()
        nfc.nextResult = .success(NFCTagIdentity(id: "tag-1"))
        let blocking = MockAppBlockingManager()
        blocking.shouldFail = true
        let persistence = InMemoryPersistenceManager()
        persistence.registeredTagID = "tag-1"
        let model = makeModel(blocking: blocking, nfc: nfc, persistence: persistence)

        await model.restore()
        await model.handleTagTap()

        XCTAssertFalse(blocking.isLocked)
        XCTAssertEqual(model.blockingState, .unlocked)
        XCTAssertEqual(persistence.blockingState, .unlocked)
        XCTAssertEqual(model.errorMessage, AppError.blockingFailed.errorDescription)
    }

    func testPersistedLockedStateIsRestored() async {
        let blocking = MockAppBlockingManager()
        let persistence = InMemoryPersistenceManager()
        persistence.hasCompletedOnboarding = true
        persistence.registeredTagID = "tag-1"
        persistence.blockingState = .locked
        let model = makeModel(blocking: blocking, persistence: persistence)

        await model.restore()

        XCTAssertEqual(model.route, .home)
        XCTAssertEqual(model.blockingState, .locked)
        XCTAssertTrue(blocking.isLocked)
    }

    func testBetaModeRegistersSimulatedTagWithoutNFC() async {
        let nfc = MockNFCManager()
        nfc.isAvailable = false
        let persistence = InMemoryPersistenceManager()
        persistence.isBetaModeEnabled = true
        let model = makeModel(nfc: nfc, persistence: persistence)

        await model.restore()
        await model.registerTag()

        XCTAssertTrue(model.hasRegisteredTag)
        XCTAssertEqual(persistence.registeredTagID, "beta-mode-tag")
        XCTAssertEqual(model.lastConfirmation, "Beta key connected")
    }

    func testBetaModeToggleDoesNotCallBlockingService() async {
        let blocking = MockAppBlockingManager()
        blocking.shouldFail = true
        let persistence = InMemoryPersistenceManager()
        persistence.isBetaModeEnabled = true
        persistence.registeredTagID = "beta-mode-tag"
        let model = makeModel(blocking: blocking, persistence: persistence)

        await model.restore()
        await model.handleTagTap()

        XCTAssertFalse(blocking.isLocked)
        XCTAssertEqual(model.blockingState, .locked)
        XCTAssertEqual(persistence.blockingState, .locked)
        XCTAssertNil(model.errorMessage)
    }

    private func makeModel(
        blocking: MockAppBlockingManager = MockAppBlockingManager(),
        nfc: MockNFCManager = MockNFCManager(),
        persistence: InMemoryPersistenceManager = InMemoryPersistenceManager()
    ) -> AppModel {
        AppModel(blockingService: blocking, nfcManager: nfc, persistence: persistence)
    }
}
