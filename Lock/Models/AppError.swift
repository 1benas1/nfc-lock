import Foundation

enum AppError: LocalizedError, Equatable {
    case authorizationDenied
    case blockingFailed
    case nfcUnavailable
    case nfcCancelled
    case unknownTag
    case tagReadFailed
    case noRegisteredTag
    case setupIncomplete

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Screen Time access is required to block selected apps."
        case .blockingFailed:
            return "The selected apps could not be updated right now."
        case .nfcUnavailable:
            return "NFC is not available on this device."
        case .nfcCancelled:
            return "The NFC scan was cancelled."
        case .unknownTag:
            return "That is not your connected key."
        case .tagReadFailed:
            return "The tag could not be read. Try again."
        case .noRegisteredTag:
            return "Connect an NFC tag before locking."
        case .setupIncomplete:
            return "Choose apps and connect your key first."
        }
    }
}
