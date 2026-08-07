import XCTest
@testable import DJMemoryCore

final class DiagnosticsReportTests: XCTestCase {
    func testBuilderSummarizesStateWithoutTrackTitles() {
        let generatedAt = Date(timeIntervalSince1970: 1_800)
        let importedAt = Date(timeIntervalSince1970: 1_700)
        let detectedAt = Date(timeIntervalSince1970: 1_600)
        let activityAt = Date(timeIntervalSince1970: 1_750)
        let app = DJSoftware(
            id: "serato",
            displayName: "Serato DJ Pro",
            bundleIdentifiers: ["com.serato.dj"],
            defaultRecordingPaths: [],
            defaultHistoryPaths: [],
            integrationDepth: .exportImport,
            notes: "test"
        )
        let archive = ArchiveMetadata(
            sessionID: UUID(),
            sourceAppID: "serato",
            detectedAt: detectedAt,
            completedAt: nil,
            sourcePath: "/source/set.wav",
            archivePath: "/archive/set.wav",
            fileSize: 42,
            originalFilename: "set.wav",
            durationSeconds: nil
        )
        let imported = ImportedTracklist(
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/history/private-set.csv"),
            tracks: [
                TrackPlay(
                    title: "Private Track",
                    artist: "Private Artist",
                    startTime: nil,
                    source: "private-set.csv",
                    confidence: 1.0
                )
            ],
            importedAt: importedAt
        )

        let report = DiagnosticsReportBuilder().build(
            generatedAt: generatedAt,
            archiveRoot: URL(fileURLWithPath: "/archive"),
            probeResults: [
                SoftwareProbeResult(
                    software: app,
                    installedApplicationURLs: [URL(fileURLWithPath: "/Applications/Serato DJ Pro.app")],
                    existingRecordingURLs: [],
                    existingHistoryURLs: []
                )
            ],
            recordingFolders: { _ in [URL(fileURLWithPath: "/recordings")] },
            historyFolders: { _ in [URL(fileURLWithPath: "/history")] },
            folderAccesses: [
                FolderAccess(appID: "serato", kind: .recordings, url: URL(fileURLWithPath: "/recordings"), bookmarkData: nil)
            ],
            archives: [archive],
            importedTracklists: [imported],
            activityEvents: [
                ActivityEvent(kind: .importTracklist, message: "Imported 1 track", detail: "private-set.csv", createdAt: activityAt)
            ]
        )

        XCTAssertEqual(report.generatedAt, generatedAt)
        XCTAssertEqual(report.totals.protectedSourceCount, 1)
        XCTAssertEqual(report.totals.configuredFolderCount, 1)
        XCTAssertEqual(report.totals.archivedSetCount, 1)
        XCTAssertEqual(report.totals.importedTracklistCount, 1)
        XCTAssertEqual(report.totals.importedTrackCount, 1)
        XCTAssertEqual(report.software.first?.recordingFolderPaths, ["/recordings"])
        XCTAssertEqual(report.imports.first?.trackCount, 1)

        let encoded = try! JSONEncoder().encode(report)
        let json = String(data: encoded, encoding: .utf8)!
        XCTAssertFalse(json.contains("Private Artist"))
        XCTAssertFalse(json.contains("Private Track"))
    }
}
