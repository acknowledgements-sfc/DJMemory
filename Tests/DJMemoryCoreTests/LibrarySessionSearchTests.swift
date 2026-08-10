import XCTest
@testable import DJMemoryCore

final class LibrarySessionSearchTests: XCTestCase {
    func testFilterMatchesArchiveAndContextFields() {
        let summary = LibrarySessionSummary(
            archive: archive(filename: "2026-08-06 2230 - Serato DJ Pro - Set.wav"),
            matchedTracklist: nil,
            context: SetContext(
                sessionID: UUID(),
                eventName: "Warehouse Set",
                venue: "Room 2",
                city: "San Francisco",
                tags: "house late",
                notes: "Peak hour"
            )
        )
        let other = LibrarySessionSummary(
            archive: archive(filename: "Practice.wav", appID: "rekordbox"),
            matchedTracklist: nil
        )

        let results = LibrarySessionSearch().filter(
            [summary, other],
            query: "room 2",
            appDisplayName: appDisplayName(for:)
        )

        XCTAssertEqual(results.map(\.archive.originalFilename), [summary.archive.originalFilename])
    }

    func testFilterMatchesAppAndTracklistFields() {
        let tracklist = ImportedTracklist(
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/Exports/private-history.csv"),
            tracks: [
                TrackPlay(title: "Night Drive", artist: "Avery", startTime: "23:10", source: "private-history.csv", confidence: 1.0)
            ]
        )
        let summary = LibrarySessionSummary(
            archive: archive(filename: "Set.wav"),
            matchedTracklist: tracklist
        )

        let appResults = LibrarySessionSearch().filter(
            [summary],
            query: "Serato DJ Pro",
            appDisplayName: appDisplayName(for:)
        )
        let trackResults = LibrarySessionSearch().filter(
            [summary],
            query: "Night Drive",
            appDisplayName: appDisplayName(for:)
        )

        XCTAssertEqual(appResults.count, 1)
        XCTAssertEqual(trackResults.count, 1)
    }

    func testBlankQueryReturnsAllSummaries() {
        let summaries = [
            LibrarySessionSummary(archive: archive(filename: "One.wav"), matchedTracklist: nil),
            LibrarySessionSummary(archive: archive(filename: "Two.wav"), matchedTracklist: nil)
        ]

        let results = LibrarySessionSearch().filter(
            summaries,
            query: " ",
            appDisplayName: appDisplayName(for:)
        )

        XCTAssertEqual(results.map(\.id), summaries.map(\.id))
    }

    func testDateFilterUsesDetectedAt() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 8, day: 9, hour: 12))!
        let today = LibrarySessionSummary(
            archive: archive(filename: "Today.wav", detectedAt: now),
            matchedTracklist: nil
        )
        let older = LibrarySessionSummary(
            archive: archive(
                filename: "Older.wav",
                detectedAt: calendar.date(byAdding: .day, value: -3, to: now)!
            ),
            matchedTracklist: nil
        )

        let filtered = LibrarySessionSearch().filter(
            [today, older],
            query: "",
            dateFilter: .today,
            appDisplayName: appDisplayName(for:),
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(filtered.map(\.archive.originalFilename), ["Today.wav"])
    }

    private func archive(
        filename: String,
        appID: String = "serato",
        detectedAt: Date = Date(timeIntervalSince1970: 100)
    ) -> ArchiveMetadata {
        let id = UUID()
        return ArchiveMetadata(
            sessionID: id,
            sourceAppID: appID,
            detectedAt: detectedAt,
            completedAt: detectedAt.addingTimeInterval(20),
            sourcePath: "/Source/\(filename)",
            archivePath: "/Archive/\(filename)",
            fileSize: 100,
            originalFilename: filename,
            durationSeconds: 60
        )
    }

    private func appDisplayName(for appID: String) -> String {
        switch appID {
        case "serato":
            return "Serato DJ Pro"
        case "rekordbox":
            return "rekordbox"
        default:
            return appID
        }
    }
}
