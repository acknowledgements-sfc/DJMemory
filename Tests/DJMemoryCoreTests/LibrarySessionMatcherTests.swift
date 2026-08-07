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

    func testSummariesDoNotMatchCollectionImports() {
        let archive = ArchiveMetadata(
            session: RecordingSession(
                sourceAppID: "rekordbox",
                detectedAt: Date(timeIntervalSince1970: 100),
                sourceURL: URL(fileURLWithPath: "/tmp/source.wav")
            ),
            originalFilename: "source.wav"
        )
        let tracklist = ImportedTracklist(
            appID: "rekordbox",
            sourceURL: URL(fileURLWithPath: "/tmp/rekordbox.xml"),
            kind: .collection,
            tracks: [
                TrackPlay(title: "Track", artist: "Artist", startTime: nil, source: "rekordbox.xml", confidence: 0.9)
            ],
            importedAt: Date(timeIntervalSince1970: 120)
        )

        let summaries = LibrarySessionMatcher().summaries(archives: [archive], importedTracklists: [tracklist])

        XCTAssertEqual(summaries.first?.trackCount, 0)
        XCTAssertNil(summaries.first?.matchedTracklist)
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

    func testManualTracklistContextOverridesNearestAutomaticMatch() {
        let archive = ArchiveMetadata(
            session: RecordingSession(
                sourceAppID: "serato",
                detectedAt: Date(timeIntervalSince1970: 100),
                sourceURL: URL(fileURLWithPath: "/tmp/source.wav")
            ),
            originalFilename: "source.wav"
        )
        let automaticTracklist = ImportedTracklist(
            id: UUID(),
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/tmp/automatic.csv"),
            tracks: [
                TrackPlay(title: "Automatic", artist: "Artist", startTime: nil, source: "automatic.csv", confidence: 0.9)
            ],
            importedAt: Date(timeIntervalSince1970: 101)
        )
        let manualTracklist = ImportedTracklist(
            id: UUID(),
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/tmp/manual.csv"),
            tracks: [
                TrackPlay(title: "Manual", artist: "Artist", startTime: nil, source: "manual.csv", confidence: 0.9)
            ],
            importedAt: Date(timeIntervalSince1970: 300)
        )
        let context = SetContext(sessionID: archive.id, manualTracklistID: manualTracklist.id)

        let summaries = LibrarySessionMatcher().summaries(
            archives: [archive],
            importedTracklists: [automaticTracklist, manualTracklist],
            setContexts: [context]
        )

        XCTAssertEqual(summaries.first?.matchedTracklist?.sourceURL.lastPathComponent, "manual.csv")
    }
}
