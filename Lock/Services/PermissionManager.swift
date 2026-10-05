import Foundation

struct PermissionManager {
    let blockingService: AppBlockingService

    func requestScreenTimeAccess() async throws {
        try await blockingService.requestAuthorization()
    }
}
