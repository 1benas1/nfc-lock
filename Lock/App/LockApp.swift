import SwiftUI

@main
struct LockApp: App {
    @StateObject private var appModel = AppModel(
        blockingService: AppBlockingManager(),
        nfcManager: CoreNFCManager(),
        persistence: UserDefaultsPersistenceManager()
    )

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appModel)
        }
    }
}
