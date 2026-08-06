import XCTest
@testable import DJMemoryCore

final class ScanCoordinatorTests: XCTestCase {
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

    func testScanRecentArchivesAudioFromRequests() throws {
        let sourceFolder = tempRoot.appendingPathComponent("Source", isDirectory: true)
        let archiveFolder = tempRoot.appendingPathComponent("Archive", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceFolder, withIntermediateDirectories: true)

        let sourceURL = sourceFolder.appendingPathComponent("set.wav")
        try Data("audio".utf8).write(to: sourceURL)

        let scanner = RecordingFolderScanner(
            archiveService: ArchiveService(archiveRoot: archiveFolder)
        )
        let coordinator = ScanCoordinator(scanner: scanner)
        let results = coordinator.scanRecent(
            requests: [FolderScanRequest(appID: "serato", folderURL: sourceFolder)]
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertNil(results.first?.errorDescription)
        XCTAssertEqual(results.first?.archivedSessions.count, 1)
    }

    func testScanRecentCapturesErrorsPerFolder() {
        let missingFolder = tempRoot.appendingPathComponent("Missing", isDirectory: true)
        let coordinator = ScanCoordinator()
        let results = coordinator.scanRecent(
            requests: [FolderScanRequest(appID: "serato", folderURL: missingFolder)]
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertNotNil(results.first?.errorDescription)
    }
}
