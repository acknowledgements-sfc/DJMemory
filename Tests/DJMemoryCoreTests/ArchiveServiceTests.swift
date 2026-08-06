import XCTest
@testable import DJMemoryCore

final class ArchiveServiceTests: XCTestCase {
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

    func testArchiveCopiesSourceAndWritesMetadata() throws {
        let sourceURL = tempRoot.appendingPathComponent("source.wav")
        let archiveRoot = tempRoot.appendingPathComponent("Archive", isDirectory: true)
        try Data("audio".utf8).write(to: sourceURL)

        let service = ArchiveService(archiveRoot: archiveRoot)
        let session = try service.archive(sourceURL: sourceURL, sourceAppID: "serato", detectedAt: Date(timeIntervalSince1970: 0))

        let archiveURL = try XCTUnwrap(session.archiveURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourceURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: service.metadataURL(for: archiveURL).path))
        XCTAssertEqual(try Data(contentsOf: sourceURL), try Data(contentsOf: archiveURL))
    }

    func testArchiveDoesNotOverwriteExistingArchive() throws {
        let sourceURL = tempRoot.appendingPathComponent("source.wav")
        let archiveRoot = tempRoot.appendingPathComponent("Archive", isDirectory: true)
        let detectedAt = Date(timeIntervalSince1970: 0)
        try Data("audio".utf8).write(to: sourceURL)

        let service = ArchiveService(archiveRoot: archiveRoot)
        let first = try service.archive(sourceURL: sourceURL, sourceAppID: "serato", detectedAt: detectedAt)
        let second = try service.archive(sourceURL: sourceURL, sourceAppID: "serato", detectedAt: detectedAt)

        XCTAssertNotEqual(first.archiveURL, second.archiveURL)
        XCTAssertTrue(try XCTUnwrap(second.archiveURL).lastPathComponent.contains(" 2."))
    }

    func testIsSourceAlreadyArchivedUsesMetadataSidecar() throws {
        let sourceURL = tempRoot.appendingPathComponent("source.wav")
        let archiveRoot = tempRoot.appendingPathComponent("Archive", isDirectory: true)
        try Data("audio".utf8).write(to: sourceURL)

        let service = ArchiveService(archiveRoot: archiveRoot)
        XCTAssertFalse(service.isSourceAlreadyArchived(sourceURL))

        try service.archive(sourceURL: sourceURL, sourceAppID: "serato")

        XCTAssertTrue(service.isSourceAlreadyArchived(sourceURL))
    }

    func testDefaultArchiveRootIsMusicDJMemory() {
        let root = ArchiveService.defaultArchiveRoot()

        XCTAssertTrue(root.path.hasSuffix("/Music/DJMemory"))
    }
}
