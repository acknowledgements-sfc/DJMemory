import XCTest
@testable import DJMemoryCore

final class TracklistAutopullTests: XCTestCase {
    private var tempRoot: URL!

    override func setUp() {
        super.setUp()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("djmemory-autopull-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempRoot)
        tempRoot = nil
        super.tearDown()
    }

    func testEmptyHistoryAppIDsReturnsNotFound() throws {
        let session = RecordingSession(
            sourceAppID: "serato",
            sourceURL: tempRoot.appendingPathComponent("set.wav")
        )
        let folderStore = FolderAccessStore(storageURL: tempRoot.appendingPathComponent("folder-access.json"))
        let tracklistStore = ImportedTracklistStore(storageURL: tempRoot.appendingPathComponent("tracklists.json"))
        let activityStore = ActivityLogStore(storageURL: tempRoot.appendingPathComponent("activity.json"))
        let contextStore = SetContextStore(storageURL: tempRoot.appendingPathComponent("contexts.json"))

        let result = try TracklistAutopull().attempt(
            session: session,
            historyAppIDs: [],
            historyAccesses: [],
            folderAccessStore: folderStore,
            importedTracklistStore: tracklistStore,
            activityLogStore: activityStore,
            setContextStore: contextStore,
            archives: [],
            importedTracklists: [],
            setContexts: []
        )

        XCTAssertEqual(result, .notFound)
    }

    func testHistoryAppIDsReturnsSourceForDJApp() {
        let ids = TracklistAutopull.historyAppIDs(
            sourceAppID: "serato",
            selectedTargetAppID: "rekordbox",
            historyAccesses: []
        )
        XCTAssertEqual(ids, ["serato"])
    }

    func testHistoryAppIDsUsesSelectedTargetForHardwareCapture() {
        let ids = TracklistAutopull.historyAppIDs(
            sourceAppID: SupportedDJSoftware.captureAppID,
            selectedTargetAppID: "traktor",
            historyAccesses: []
        )
        XCTAssertEqual(ids, ["traktor"])
    }

    func testHistoryAppIDsFallsBackToDefaultsAndBookmarksForHardware() {
        let bookmarkAccess = FolderAccess(
            appID: "djay",
            kind: .history,
            url: tempRoot.appendingPathComponent("djay-history", isDirectory: true),
            bookmarkData: nil
        )
        let ids = TracklistAutopull.historyAppIDs(
            sourceAppID: SupportedDJSoftware.pioneerHardwareAppID,
            selectedTargetAppID: nil,
            historyAccesses: [bookmarkAccess]
        )
        XCTAssertTrue(ids.contains("serato"))
        XCTAssertTrue(ids.contains("virtualdj"))
        XCTAssertTrue(ids.contains("traktor"))
        XCTAssertTrue(ids.contains("djay"))
        XCTAssertFalse(ids.contains(SupportedDJSoftware.captureAppID))
    }
}
