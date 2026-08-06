import Foundation

public struct ImportedTracklist: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let sourceURL: URL
    public let tracks: [TrackPlay]
    public let importedAt: Date

    public init(id: UUID = UUID(), sourceURL: URL, tracks: [TrackPlay], importedAt: Date = Date()) {
        self.id = id
        self.sourceURL = sourceURL
        self.tracks = tracks
        self.importedAt = importedAt
    }
}
