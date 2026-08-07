import XCTest
@testable import DJMemoryCore

final class DiagnosticsReportTests: XCTestCase {
    func testBuilderSummarizesStateWithoutTrackTitles() {
        let generatedAt = Date(timeIntervalSince1970: 1_800)
        let importedAt = Date(timeIntervalSince1970: 1_700)
        let detectedAt = Date(timeIntervalSince1970: 1_600)
        let activityAt = Date(timeIntervalSince1970: 1_750)
        let homeDirectory = URL(fileURLWithPath: "/Users/private-dj", isDirectory: true)
        let app = DJSoftware(
            id: "serato",
            displayName: "Serato DJ Pro",
            bundleIdentifiers: ["com.serato.dj"],
            defaultRecordingPaths: [],
            defaultHistoryPaths: [],
            integrationDepth: .exportImport,
            supportStatus: .supported,
            notes: "test"
        )
        let archive = ArchiveMetadata(
            sessionID: UUID(),
            sourceAppID: "serato",
            detectedAt: detectedAt,
            completedAt: nil,
            sourcePath: "/Users/private-dj/Music/_Serato_/Recording/set.wav",
            archivePath: "/Users/private-dj/Music/DJMemory/set.wav",
            fileSize: 42,
            originalFilename: "set.wav",
            durationSeconds: nil
        )
        let imported = ImportedTracklist(
            appID: "serato",
            sourceURL: URL(fileURLWithPath: "/Users/private-dj/Music/_Serato_/History Export/private-set.csv"),
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

        let report = DiagnosticsReportBuilder(homeDirectory: homeDirectory).build(
            generatedAt: generatedAt,
            archiveRoot: URL(fileURLWithPath: "/Users/private-dj/Music/DJMemory"),
            probeResults: [
                SoftwareProbeResult(
                    software: app,
                    installedApplicationURLs: [URL(fileURLWithPath: "/Applications/Serato DJ Pro.app")],
                    existingRecordingURLs: [],
                    existingHistoryURLs: []
                )
            ],
            recordingFolders: { _ in [URL(fileURLWithPath: "/Users/private-dj/Music/_Serato_/Recording")] },
            historyFolders: { _ in [URL(fileURLWithPath: "/Users/private-dj/Music/_Serato_/History Export")] },
            folderAccesses: [
                FolderAccess(
                    appID: "serato",
                    kind: .recordings,
                    url: URL(fileURLWithPath: "/Users/private-dj/Music/_Serato_/Recording"),
                    bookmarkData: nil
                )
            ],
            archives: [archive],
            importedTracklists: [imported],
            activityEvents: [
                ActivityEvent(
                    kind: .importTracklist,
                    message: "Imported 1 track",
                    detail: "/Users/private-dj/Music/_Serato_/History Export/private-set.csv",
                    createdAt: activityAt
                )
            ]
        )

        XCTAssertEqual(report.generatedAt, generatedAt)
        XCTAssertEqual(report.totals.protectedSourceCount, 1)
        XCTAssertEqual(report.totals.configuredFolderCount, 1)
        XCTAssertEqual(report.totals.archivedSetCount, 1)
        XCTAssertEqual(report.totals.importedTracklistCount, 1)
        XCTAssertEqual(report.totals.importedTrackCount, 1)
        XCTAssertEqual(report.archiveRootPath, "~/Music/DJMemory")
        XCTAssertEqual(report.software.first?.recordingFolderPaths, ["~/Music/_Serato_/Recording"])
        XCTAssertEqual(report.imports.first?.sourcePath, "~/Music/_Serato_/History Export/private-set.csv")
        XCTAssertEqual(report.archives.first?.sourcePath, "~/Music/_Serato_/Recording/set.wav")
        XCTAssertEqual(report.recentActivity.first?.detail, "~/Music/_Serato_/History Export/private-set.csv")
        XCTAssertEqual(report.imports.first?.trackCount, 1)

        let encoded = try! JSONEncoder().encode(report)
        let json = String(data: encoded, encoding: .utf8)!
        XCTAssertFalse(json.contains("Private Artist"))
        XCTAssertFalse(json.contains("Private Track"))
        XCTAssertFalse(json.contains("/Users/private-dj"))
    }
}
