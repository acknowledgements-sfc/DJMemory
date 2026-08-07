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

    func testArchiveMetadataIncludesDurationField() throws {
        let sourceURL = tempRoot.appendingPathComponent("source.wav")
        let archiveRoot = tempRoot.appendingPathComponent("Archive", isDirectory: true)
        try Data("audio".utf8).write(to: sourceURL)

        let service = ArchiveService(archiveRoot: archiveRoot)
        let session = try service.archive(sourceURL: sourceURL, sourceAppID: "serato", detectedAt: Date(timeIntervalSince1970: 0))
        let archiveURL = try XCTUnwrap(session.archiveURL)
        let metadataURL = service.metadataURL(for: archiveURL)
        let data = try Data(contentsOf: metadataURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let metadata = try decoder.decode(ArchiveMetadata.self, from: data)

        XCTAssertNil(metadata.durationSeconds)
    }

    func testArchiveMetadataStoresMeasuredDuration() throws {
        let sourceURL = tempRoot.appendingPathComponent("source.wav")
        let archiveRoot = tempRoot.appendingPathComponent("Archive", isDirectory: true)
        try Data("audio".utf8).write(to: sourceURL)

        let service = ArchiveService(
            archiveRoot: archiveRoot,
            durationReader: StubAudioDurationReader(duration: 3_661.5)
        )
        let session = try service.archive(sourceURL: sourceURL, sourceAppID: "serato")
        let archiveURL = try XCTUnwrap(session.archiveURL)
        let data = try Data(contentsOf: service.metadataURL(for: archiveURL))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let metadata = try decoder.decode(ArchiveMetadata.self, from: data)

        XCTAssertEqual(metadata.durationSeconds, 3_661.5)
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

private struct StubAudioDurationReader: AudioDurationReading {
    let duration: Double?

    func durationSeconds(for url: URL) -> Double? {
        duration
    }
}
