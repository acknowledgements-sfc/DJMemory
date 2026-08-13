import XCTest
@testable import DJMemoryCore

final class AppAudioCaptureBackendSelectorTests: XCTestCase {
    func testPrefersProcessAudioTapWhenSupported() {
        XCTAssertEqual(
            AppAudioCaptureBackendSelector.preferredBackend(processTapSupported: true, forceScreenCaptureKit: false),
            .processAudioTap
        )
    }

    func testFallsBackToScreenCaptureKitWhenProcessTapUnsupported() {
        XCTAssertEqual(
            AppAudioCaptureBackendSelector.preferredBackend(processTapSupported: false, forceScreenCaptureKit: false),
            .screenCaptureKit
        )
    }

    func testCanForceScreenCaptureKitForFallbackVerification() {
        XCTAssertEqual(
            AppAudioCaptureBackendSelector.preferredBackend(processTapSupported: true, forceScreenCaptureKit: true),
            .screenCaptureKit
        )
    }
}
