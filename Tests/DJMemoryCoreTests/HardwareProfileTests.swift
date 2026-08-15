import XCTest
@testable import DJMemoryCore

final class HardwareProfileTests: XCTestCase {
    func testCatalogIncludesRequestedPioneerModels() {
        let ids = Set(SupportedHardware.all.map(\.id))
        for id in ["xdj-rx2","xdj-rx3","xdj-xz","xdj-az","cdj-2000","cdj-2000nxs","cdj-3000","djm-900","djm-v10","djm-v10lf"] {
            XCTAssertTrue(ids.contains(id))
        }
    }

    func testSoftwareCatalogIncludesCaptureAndPioneerHardware() {
        let ids = Set(SupportedDJSoftware.all.map(\.id))
        XCTAssertTrue(ids.contains(SupportedDJSoftware.captureAppID))
        XCTAssertTrue(ids.contains(SupportedDJSoftware.pioneerHardwareAppID))
    }

    func testPioneerRECFilenameIsAudio() {
        XCTAssertTrue(FileStabilityChecker().isAudioFile(URL(fileURLWithPath: "/tmp/PIONEERREC/REC001.WAV")))
    }

    func testXDJXZHintDescribesLaptopUSBDualRoute() {
        let hint = SupportedHardware.profile(id: "xdj-xz")?.captureHint ?? ""
        XCTAssertTrue(hint.contains("Folder Protection"))
        XCTAssertTrue(hint.contains("Input Capture"))
        XCTAssertTrue(hint.contains("PIONEERREC"))
    }
}
