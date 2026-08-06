import Foundation

public struct ImportedTracklist: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let appID: String
    public let sourceURL: URL
    public let tracks: [TrackPlay]
    public let importedAt: Date

    public init(id: UUID = UUID(), appID: String, sourceURL: URL, tracks: [TrackPlay], importedAt: Date = Date()) {
        self.id = id
        self.appID = appID
        self.sourceURL = sourceURL
        self.tracks = tracks
        self.importedAt = importedAt
    }
}
