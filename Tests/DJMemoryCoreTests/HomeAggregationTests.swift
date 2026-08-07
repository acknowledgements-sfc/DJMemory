import XCTest
@testable import DJMemoryCore

final class DJProfileStoreTests: XCTestCase {
    func testEmptyProfileHasNoInitials() {
        XCTAssertNil(DJProfile().initials)
        XCTAssertNil(DJProfile().firstName)
    }

    func testInitialsFromDisplayName() {
        XCTAssertEqual(DJProfile(displayName: "Ada Lovelace").initials, "AL")
        XCTAssertEqual(DJProfile(displayName: "Prince").initials, "P")
        XCTAssertEqual(DJProfile(displayName: "Ada Lovelace").firstName, "Ada")
    }

    func testLegacyEmptyJSONDecodes() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("profile.json")
        try Data("{}".utf8).write(to: url)
        let profile = try DJProfileStore(storageURL: url).load()
        XCTAssertNil(profile.displayName)
    }
}

final class LibraryStatisticsTests: XCTestCase {
    func testEmptyLibrary() {
        let stats = LibraryStatisticsCalculator.calculate(archives: [], summaries: [])
        XCTAssertEqual(stats.totalDurationSeconds, 0)
        XCTAssertEqual(stats.totalFileSize, 0)
        XCTAssertEqual(stats.setsThisMonth, 0)
        XCTAssertEqual(stats.unmatchedCount, 0)
        XCTAssertNil(stats.consecutiveWeeksRunning)
    }

    func testSumsAndUnmatched() {
        let a = ArchiveMetadata(
            sessionID: UUID(),
            sourceAppID: "serato",
            detectedAt: Date(),
            completedAt: nil,
            sourcePath: "/a",
            archivePath: "/A",
            fileSize: 100,
            originalFilename: "a.wav",
            durationSeconds: 60,
            sourceFingerprint: "1"
        )
        let b = ArchiveMetadata(
            sessionID: UUID(),
            sourceAppID: "serato",
            detectedAt: Date(),
            completedAt: nil,
            sourcePath: "/b",
            archivePath: "/B",
            fileSize: 50,
            originalFilename: "b.wav",
            durationSeconds: nil,
            sourceFingerprint: "2"
        )
        let summaries = [
            LibrarySessionSummary(archive: a, matchedTracklist: nil),
            LibrarySessionSummary(archive: b, matchedTracklist: ImportedTracklist(appID: "serato", sourceURL: URL(fileURLWithPath: "/t.csv"), tracks: []))
        ]
        let stats = LibraryStatisticsCalculator.calculate(archives: [a, b], summaries: summaries)
        XCTAssertEqual(stats.totalDurationSeconds, 60)
        XCTAssertEqual(stats.totalFileSize, 150)
        XCTAssertEqual(stats.unmatchedCount, 1)
        XCTAssertEqual(stats.setsThisMonth, 2)
    }
}

final class CrossSetAggregationTests: XCTestCase {
    func testCollectionImportsExcluded() {
        let history = ImportedTracklist(
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/h.csv"),
            kind: .setHistory,
            tracks: [TrackPlay(title: "A", artist: "X", startTime: nil, source: "t", confidence: 1)]
        )
        let collection = ImportedTracklist(
            appID: "rekordbox",
            sourceURL: URL(fileURLWithPath: "/c.xml"),
            kind: .collection,
            tracks: [
                TrackPlay(title: "A", artist: "X", startTime: nil, source: "t", confidence: 1),
                TrackPlay(title: "B", artist: "Y", startTime: nil, source: "t", confidence: 1)
            ]
        )
        let top = CrossSetAggregation.topTracks(from: [history, collection])
        XCTAssertEqual(top.count, 1)
        XCTAssertEqual(top[0].title, "A")
        XCTAssertEqual(top[0].playCount, 1)
    }

    func testMixedCaseTags() {
        let contexts = [
            SetContext(sessionID: UUID(), tags: "Techno, House"),
            SetContext(sessionID: UUID(), tags: "techno, Disco")
        ]
        let tags = CrossSetAggregation.tags(from: contexts)
        XCTAssertEqual(tags.first { $0.display.lowercased() == "techno" }?.count, 2)
        XCTAssertEqual(tags.first { $0.display.lowercased() == "techno" }?.display, "Techno")
    }

    func testVenuesSkipEmpty() {
        let contexts = [
            SetContext(sessionID: UUID(), venue: "Fabric", city: "London"),
            SetContext(sessionID: UUID(), venue: "", city: "London"),
            SetContext(sessionID: UUID(), venue: "Fabric", city: "London")
        ]
        let venues = CrossSetAggregation.venues(from: contexts)
        XCTAssertEqual(venues.count, 1)
        XCTAssertEqual(venues[0].setCount, 2)
    }
}
