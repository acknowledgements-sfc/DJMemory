import XCTest
@testable import DJMemoryCore

final class FileStabilityCheckerTests: XCTestCase {
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

    func testRecentAudioFilesOnlyReturnsAudioFiles() throws {
        let wavURL = tempRoot.appendingPathComponent("set.wav")
        let textURL = tempRoot.appendingPathComponent("notes.txt")
        try Data("audio".utf8).write(to: wavURL)
        try Data("notes".utf8).write(to: textURL)

        let checker = FileStabilityChecker()
        let urls = try checker.recentAudioFiles(in: tempRoot, modifiedAfter: .distantPast)

        XCTAssertEqual(urls.map(\.lastPathComponent), [wavURL.lastPathComponent])
    }

    func testIsStableComparesCurrentSnapshotToPreviousSnapshot() throws {
        let wavURL = tempRoot.appendingPathComponent("set.wav")
        try Data("audio".utf8).write(to: wavURL)

        let checker = FileStabilityChecker()
        let snapshot = try checker.snapshot(for: wavURL)

        XCTAssertTrue(try checker.isStable(url: wavURL, previousSnapshot: snapshot))
    }
}
