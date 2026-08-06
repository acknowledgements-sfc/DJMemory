import Foundation

public struct ArchiveMetadata: Identifiable, Codable, Equatable, Sendable {
    public let sessionID: UUID
    public let sourceAppID: String
    public let detectedAt: Date
    public let completedAt: Date?
    public let sourcePath: String
    public let archivePath: String
    public let fileSize: Int64
    public let originalFilename: String

    public var id: UUID { sessionID }

    public init(session: RecordingSession, originalFilename: String) {
        self.sessionID = session.id
        self.sourceAppID = session.sourceAppID
        self.detectedAt = session.detectedAt
        self.completedAt = session.completedAt
        self.sourcePath = session.sourceURL.path
        self.archivePath = session.archiveURL?.path ?? ""
        self.fileSize = session.fileSize ?? 0
        self.originalFilename = originalFilename
    }
}
