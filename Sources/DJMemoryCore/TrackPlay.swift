import Foundation

public struct TrackPlay: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let artist: String
    public let startTime: String?
    public let source: String
    public let confidence: Double

    public init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        startTime: String?,
        source: String,
        confidence: Double
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.startTime = startTime
        self.source = source
        self.confidence = confidence
    }
}
