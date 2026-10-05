import CoreNFC
import Foundation

struct NFCTagIdentity: Codable, Equatable {
    let id: String
}

protocol NFCManaging: AnyObject {
    var isAvailable: Bool { get }
    func scanTag(prompt: String) async throws -> NFCTagIdentity
    func isRegisteredTag(_ tag: NFCTagIdentity, registeredID: String?) -> Bool
}

final class CoreNFCManager: NSObject, NFCManaging {
    private var continuation: CheckedContinuation<NFCTagIdentity, Error>?
    private var session: NFCTagReaderSession?

    var isAvailable: Bool {
        NFCTagReaderSession.readingAvailable
    }

    func scanTag(prompt: String) async throws -> NFCTagIdentity {
        guard isAvailable else { throw AppError.nfcUnavailable }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            guard let session = NFCTagReaderSession(
                pollingOption: [.iso14443, .iso15693, .iso18092],
                delegate: self,
                queue: nil
            ) else {
                finish(with: .failure(AppError.nfcUnavailable))
                return
            }

            self.session = session
            session.alertMessage = prompt
            session.begin()
        }
    }

    func isRegisteredTag(_ tag: NFCTagIdentity, registeredID: String?) -> Bool {
        registeredID == tag.id
    }

    private func finish(with result: Result<NFCTagIdentity, Error>) {
        let continuation = continuation
        self.continuation = nil
        session = nil

        switch result {
        case .success(let tag):
            continuation?.resume(returning: tag)
        case .failure(let error):
            continuation?.resume(throwing: error)
        }
    }
}

extension CoreNFCManager: NFCTagReaderSessionDelegate {
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if let readerError = error as? NFCReaderError,
           readerError.code == .readerSessionInvalidationErrorUserCanceled {
            finish(with: .failure(AppError.nfcCancelled))
        } else {
            finish(with: .failure(AppError.tagReadFailed))
        }
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tag found.")
            finish(with: .failure(AppError.tagReadFailed))
            return
        }

        session.connect(to: tag) { [weak self] error in
            guard let self else { return }

            if error != nil {
                session.invalidate(errorMessage: "Unable to read this tag.")
                finish(with: .failure(AppError.tagReadFailed))
                return
            }

            let identifier: Data
            switch tag {
            case .miFare(let tag):
                identifier = tag.identifier
            case .iso7816(let tag):
                identifier = tag.identifier
            case .iso15693(let tag):
                identifier = tag.identifier
            case .feliCa(let tag):
                identifier = tag.currentIDm
            @unknown default:
                session.invalidate(errorMessage: "Unsupported tag.")
                finish(with: .failure(AppError.tagReadFailed))
                return
            }

            let tagID = identifier.map { String(format: "%02hhx", $0) }.joined()
            session.alertMessage = "Key detected."
            session.invalidate()
            finish(with: .success(NFCTagIdentity(id: tagID)))
        }
    }
}
