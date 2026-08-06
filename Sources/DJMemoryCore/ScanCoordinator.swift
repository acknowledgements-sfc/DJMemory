import Foundation

public struct FolderScanRequest: Equatable, Sendable {
    public let appID: String
    public let folderURL: URL

    public init(appID: String, folderURL: URL) {
        self.appID = appID
        self.folderURL = folderURL
    }
}

public struct FolderScanResult: Equatable, Sendable {
    public let appID: String
    public let folderURL: URL
    public let archivedSessions: [RecordingSession]
    public let errorDescription: String?

    public init(appID: String, folderURL: URL, archivedSessions: [RecordingSession], errorDescription: String?) {
        self.appID = appID
        self.folderURL = folderURL
        self.archivedSessions = archivedSessions
        self.errorDescription = errorDescription
    }
}

public struct ScanCoordinator {
    private let scanner: RecordingFolderScanner
    private let calendar: Calendar

    public init(scanner: RecordingFolderScanner = RecordingFolderScanner(), calendar: Calendar = .current) {
        self.scanner = scanner
        self.calendar = calendar
    }

    public func scanRecent(requests: [FolderScanRequest], hoursBack: Int = 24, now: Date = Date()) -> [FolderScanResult] {
        let cutoff = calendar.date(byAdding: .hour, value: -hoursBack, to: now) ?? .distantPast

        return requests.map { request in
            do {
                let sessions = try scanner.archiveRecentStableFiles(
                    in: request.folderURL,
                    sourceAppID: request.appID,
                    modifiedAfter: cutoff
                )

                return FolderScanResult(
                    appID: request.appID,
                    folderURL: request.folderURL,
                    archivedSessions: sessions,
                    errorDescription: nil
                )
            } catch {
                return FolderScanResult(
                    appID: request.appID,
                    folderURL: request.folderURL,
                    archivedSessions: [],
                    errorDescription: error.localizedDescription
                )
            }
        }
    }
}
