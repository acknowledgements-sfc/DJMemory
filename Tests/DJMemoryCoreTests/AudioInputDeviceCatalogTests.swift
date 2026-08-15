import XCTest
@testable import DJMemoryCore

final class AudioInputDeviceCatalogTests: XCTestCase {
    func testPioneerHeuristicMatchesKnownHardware() {
        let fixtures: [(String, String, Bool)] = [
            ("XDJ-XZ", "Pioneer DJ", true),
            ("DJM-V10", "Pioneer", true),
            ("CDJ-3000", "Pioneer DJ", true),
            ("XDJ-RX3", "", true),
            ("MacBook Pro Microphone", "Apple Inc.", false),
            ("USB Audio Device", "Generic", false),
            ("Scarlett 2i2", "Focusrite", false)
        ]
        for (name, manufacturer, expected) in fixtures {
            let device = AudioInputDevice(id: name, name: name, manufacturer: manufacturer)
            XCTAssertEqual(device.isLikelyPioneerDJHardware, expected, "\(name) \(manufacturer)")
        }
    }

    func testListInputsReturnsUniqueIDs() {
        let devices = AudioInputDeviceCatalog.listInputs()
        XCTAssertEqual(Set(devices.map(\.id)).count, devices.count)
    }

    func testPreferredDefaultPicksPioneerFirst() {
        let mic = AudioInputDevice(id: "mic", name: "MacBook Pro Microphone", manufacturer: "Apple Inc.")
        let xz = AudioInputDevice(id: "xz", name: "XDJ-XZ", manufacturer: "Pioneer DJ")
        XCTAssertEqual(AudioInputDeviceCatalog.preferredDefault(from: [mic, xz])?.id, "xz")
        XCTAssertEqual(AudioInputDeviceCatalog.preferredDefault(from: [mic])?.id, "mic")
    }

    func testUnknownUIDDoesNotResolveToAudioDeviceID() {
        XCTAssertNil(AudioInputDeviceCatalog.audioDeviceID(forUID: ""))
        XCTAssertNil(AudioInputDeviceCatalog.audioDeviceID(forUID: "djmemory-missing-uid-\(UUID().uuidString)"))
    }

    func testListedInputUIDsResolveToAudioDeviceIDs() {
        for device in AudioInputDeviceCatalog.listInputs() {
            XCTAssertNotNil(AudioInputDeviceCatalog.audioDeviceID(forUID: device.id), device.id)
        }
    }
}

final class DualRoutePolicyTests: XCTestCase {
    func testBothPostureAutoSwitchesAndWatchesWhenPioneerPresent() {
        XCTAssertTrue(DualRoutePolicy.shouldAutoSwitchToInput(posture: .both, pioneerPresent: true, userSuppressedAutoSwitch: false))
        XCTAssertTrue(DualRoutePolicy.shouldUnattendedWatch(posture: .both, pioneerPresent: true, userDisarmedInput: false))
        XCTAssertFalse(DualRoutePolicy.shouldUnattendedWatch(posture: .both, pioneerPresent: true, userDisarmedInput: true))
        XCTAssertFalse(DualRoutePolicy.shouldAutoSwitchToInput(posture: .both, pioneerPresent: true, userSuppressedAutoSwitch: true))
    }

    func testFolderOnlyNeverAutoSwitches() {
        XCTAssertFalse(DualRoutePolicy.shouldAutoSwitchToInput(posture: .folderOnly, pioneerPresent: true, userSuppressedAutoSwitch: false))
        XCTAssertFalse(DualRoutePolicy.shouldUnattendedWatch(posture: .folderOnly, pioneerPresent: true, userDisarmedInput: false))
        XCTAssertFalse(DualRoutePolicy.shouldAutoSelectPioneer(posture: .folderOnly))
    }

    func testOnDemandSelectsButDoesNotUnattendedWatch() {
        XCTAssertFalse(DualRoutePolicy.shouldAutoSwitchToInput(posture: .folderPrimaryInputOnDemand, pioneerPresent: true, userSuppressedAutoSwitch: false))
        XCTAssertFalse(DualRoutePolicy.shouldUnattendedWatch(posture: .folderPrimaryInputOnDemand, pioneerPresent: true, userDisarmedInput: false))
        XCTAssertTrue(DualRoutePolicy.shouldAutoSelectPioneer(posture: .folderPrimaryInputOnDemand))
    }

    func testFallbackToAppAudioWhenPioneerLeaves() {
        XCTAssertTrue(DualRoutePolicy.shouldFallBackToAppAudio(posture: .both, pioneerPresent: false, userSuppressedAutoSwitch: false))
        XCTAssertFalse(DualRoutePolicy.shouldFallBackToAppAudio(posture: .both, pioneerPresent: true, userSuppressedAutoSwitch: false))
        XCTAssertFalse(DualRoutePolicy.shouldFallBackToAppAudio(posture: .both, pioneerPresent: false, userSuppressedAutoSwitch: true))
        XCTAssertFalse(DualRoutePolicy.shouldFallBackToAppAudio(posture: .folderOnly, pioneerPresent: false, userSuppressedAutoSwitch: false))
    }
}
