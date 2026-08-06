import XCTest
@testable import DJMemoryCore

final class SessionLibraryTests: XCTestCase {
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

    func testArchivedMetadataReadsSidecars() throws {
        let sourceURL = tempRoot.appendingPathComponent("source.wav")
        let archiveRoot = tempRoot.appendingPathComponent("Archive", isDirectory: true)
        try Data("audio".utf8).write(to: sourceURL)

        let archiveService = ArchiveService(archiveRoot: archiveRoot)
        try archiveService.archive(sourceURL: sourceURL, sourceAppID: "serato")

        let library = SessionLibrary(archiveRoot: archiveRoot)
        let sessions = try library.archivedMetadata()

        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.originalFilename, "source.wav")
    }
}
