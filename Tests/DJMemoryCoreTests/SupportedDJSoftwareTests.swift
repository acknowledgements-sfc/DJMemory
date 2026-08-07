import XCTest
@testable import DJMemoryCore

final class SupportedDJSoftwareTests: XCTestCase {
    func testSupportedSoftwareContainsExpectedAdapters() {
        let ids = Set(SupportedDJSoftware.all.map(\.id))

        XCTAssertEqual(ids, ["serato", "rekordbox", "djay", "virtualdj", "traktor"])
    }

    func testEveryAdapterHasDisplayNameAndNotes() {
        for software in SupportedDJSoftware.all {
            XCTAssertFalse(software.displayName.isEmpty)
            XCTAssertFalse(software.notes.isEmpty)
        }
    }

    func testAdaptersExposeHonestSupportStatus() {
        let statuses = Dictionary(uniqueKeysWithValues: SupportedDJSoftware.all.map { ($0.id, $0.supportStatus) })

        XCTAssertEqual(statuses["serato"], .supported)
        XCTAssertEqual(statuses["rekordbox"], .supported)
        XCTAssertEqual(statuses["traktor"], .supported)
        XCTAssertEqual(statuses["virtualdj"], .partial)
        XCTAssertEqual(statuses["djay"], .manualSetup)
    }

    func testDjayIncludesDocumentedRecordingDefaults() throws {
        let djay = try XCTUnwrap(SupportedDJSoftware.all.first { $0.id == "djay" })

        XCTAssertEqual(djay.defaultRecordingPaths, ["~/Music/djay/Recordings", "~/Music/djay Pro 2/Recordings"])
        XCTAssertTrue(djay.defaultHistoryPaths.isEmpty)
    }
}
