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
}
