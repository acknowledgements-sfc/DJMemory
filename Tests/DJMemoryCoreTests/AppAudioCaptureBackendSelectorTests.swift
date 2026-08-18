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

    // NOTE: `virtualEnabled: true` is passed explicitly to the tests below so they exercise
    // the virtual-selection LOGIC (app-context, transport match, etc.) independent of the
    // PR2.1 safety gate, which defaults OFF. The gate itself is covered by
    // `testSafetyGateDisablesVirtualBackendByDefault`.

    func testPrefersSeratoVirtualDeviceWhenSeratoIsRunning() {
        let selection = AppAudioCaptureBackendSelector.preferredSelection(
            targetSoftware: Self.serato,
            inputDevices: [Self.seratoVirtualAudio],
            runningSoftwareIDs: ["serato"],
            processTapSupported: true,
            forceScreenCaptureKit: false,
            virtualEnabled: true
        )
        guard case .virtualInputDevice(let device, let softwareID) = selection else {
            return XCTFail("expected virtualInputDevice, got \(selection)")
        }
        XCTAssertEqual(device.id, Self.seratoVirtualAudio.id)
        XCTAssertEqual(softwareID, "serato")
        XCTAssertEqual(selection.kind, .virtualInputDevice)
    }

    func testSafetyGateDisablesVirtualBackendByDefault() {
        // With the gate OFF (the default), even the ideal virtual-device conditions must fall
        // back to Process Audio Tap — the AVAudioEngine virtual backend OOMs the machine.
        let selection = AppAudioCaptureBackendSelector.preferredSelection(
            targetSoftware: Self.serato,
            inputDevices: [Self.seratoVirtualAudio],
            runningSoftwareIDs: ["serato"],
            processTapSupported: true,
            forceScreenCaptureKit: false,
            virtualEnabled: false
        )
        XCTAssertEqual(selection, .processAudioTap)
    }

    func testFallsBackToProcessTapWhenSeratoHasNoVirtualDevice() {
        let selection = AppAudioCaptureBackendSelector.preferredSelection(
            targetSoftware: Self.serato,
            inputDevices: [],
            runningSoftwareIDs: ["serato"],
            processTapSupported: true,
            forceScreenCaptureKit: false,
            virtualEnabled: true
        )
        XCTAssertEqual(selection, .processAudioTap)
    }

    func testRekordboxDoesNotSelectSeratoVirtualDevice() {
        let selection = AppAudioCaptureBackendSelector.preferredSelection(
            targetSoftware: Self.rekordbox,
            inputDevices: [Self.seratoVirtualAudio],
            runningSoftwareIDs: ["rekordbox", "serato"],
            processTapSupported: true,
            forceScreenCaptureKit: false,
            virtualEnabled: true
        )
        XCTAssertEqual(selection, .processAudioTap)
    }

    func testNoDetectedAppDoesNotSelectVirtualBackend() {
        let selection = AppAudioCaptureBackendSelector.preferredSelection(
            targetSoftware: Self.serato,
            inputDevices: [Self.seratoVirtualAudio],
            runningSoftwareIDs: [],
            processTapSupported: true,
            forceScreenCaptureKit: false,
            virtualEnabled: true
        )
        XCTAssertEqual(selection, .processAudioTap)

        let nilTarget = AppAudioCaptureBackendSelector.preferredSelection(
            targetSoftware: nil,
            inputDevices: [Self.seratoVirtualAudio],
            runningSoftwareIDs: ["serato"],
            processTapSupported: true,
            forceScreenCaptureKit: false,
            virtualEnabled: true
        )
        XCTAssertEqual(nilTarget, .processAudioTap)
    }

    func testVirtualBindFailureFallsBackToProcessTap() {
        XCTAssertEqual(
            AppAudioCaptureBackendSelector.fallbackAfterVirtualBindFailure(
                processTapSupported: true,
                forceScreenCaptureKit: false
            ),
            .processAudioTap
        )
        XCTAssertEqual(
            AppAudioCaptureBackendSelector.fallbackAfterVirtualBindFailure(
                processTapSupported: false,
                forceScreenCaptureKit: false
            ),
            .screenCaptureKit
        )
    }

    private static let seratoVirtualAudio = AudioInputDevice(
        id: "sva",
        name: "Serato Virtual Audio",
        manufacturer: "Serato",
        transportType: .virtual
    )

    private static var serato: DJSoftware {
        SupportedDJSoftware.all.first { $0.id == "serato" }!
    }

    private static var rekordbox: DJSoftware {
        SupportedDJSoftware.all.first { $0.id == "rekordbox" }!
    }
}
