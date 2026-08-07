import XCTest
@testable import DJMemoryCore

final class LibrarySessionMatcherTests: XCTestCase {
    func testSummariesMatchTracklistByAppID() {
        let archive = ArchiveMetadata(
            session: RecordingSession(
                sourceAppID: "serato",
                detectedAt: Date(timeIntervalSince1970: 100),
                sourceURL: URL(fileURLWithPath: "/tmp/source.wav")
            ),
            originalFilename: "source.wav"
        )
        let tracklist = ImportedTracklist(
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/tmp/history.csv"),
            tracks: [
                TrackPlay(title: "Track", artist: "Artist", startTime: nil, source: "history.csv", confidence: 0.9)
            ],
            importedAt: Date(timeIntervalSince1970: 120)
        )

        let summaries = LibrarySessionMatcher().summaries(archives: [archive], importedTracklists: [tracklist])

        XCTAssertEqual(summaries.first?.trackCount, 1)
        XCTAssertEqual(summaries.first?.matchedTracklist?.sourceURL.lastPathComponent, "history.csv")
    }

    func testSummariesDoNotMatchDifferentAppID() {
        let archive = ArchiveMetadata(
            session: RecordingSession(
                sourceAppID: "serato",
                detectedAt: Date(timeIntervalSince1970: 100),
                sourceURL: URL(fileURLWithPath: "/tmp/source.wav")
            ),
            originalFilename: "source.wav"
        )
        let tracklist = ImportedTracklist(
            appID: "rekordbox",
            sourceURL: URL(fileURLWithPath: "/tmp/rekordbox.xml"),
            tracks: [
                TrackPlay(title: "Track", artist: "Artist", startTime: nil, source: "rekordbox.xml", confidence: 0.9)
            ],
            importedAt: Date(timeIntervalSince1970: 120)
        )

        let summaries = LibrarySessionMatcher().summaries(archives: [archive], importedTracklists: [tracklist])

        XCTAssertNil(summaries.first?.matchedTracklist)
    }
}
