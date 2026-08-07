import XCTest
@testable import DJMemoryCore

final class ImportedTracklistStoreTests: XCTestCase {
    private var tempRoot: URL!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("DJMemoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
        tempRoot = nil
    }

    func testSavePersistsImportedTracklist() throws {
        let store = ImportedTracklistStore(storageURL: tempRoot.appendingPathComponent("tracklists.json"))
        let track = TrackPlay(title: "Good Life", artist: "Inner City", startTime: "00:00", source: "test.csv", confidence: 0.9)
        let tracklist = ImportedTracklist(
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/tmp/test.csv"),
            tracks: [track]
        )

        try store.save(tracklist)

        let imported = try store.all()
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported.first?.tracks.first?.title, "Good Life")
    }

    func testSaveReplacesSameAppAndSource() throws {
        let store = ImportedTracklistStore(storageURL: tempRoot.appendingPathComponent("tracklists.json"))
        let sourceURL = URL(fileURLWithPath: "/tmp/test.csv")
        let first = ImportedTracklist(appID: "serato", sourceURL: sourceURL, tracks: [])
        let second = ImportedTracklist(appID: "serato", sourceURL: sourceURL, tracks: [
            TrackPlay(title: "Show Me Love", artist: "Robin S", startTime: nil, source: "test.csv", confidence: 0.9)
        ])

        try store.save(first)
        try store.save(second)

        let imported = try store.all()
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported.first?.tracks.first?.title, "Show Me Love")
    }

    func testRemoveDeletesImportedTracklistByID() throws {
        let store = ImportedTracklistStore(storageURL: tempRoot.appendingPathComponent("tracklists.json"))
        let tracklist = ImportedTracklist(appID: "serato", sourceURL: URL(fileURLWithPath: "/tmp/test.csv"), tracks: [])

        try store.save(tracklist)
        try store.remove(id: tracklist.id)

        XCTAssertTrue(try store.all().isEmpty)
    }
}
