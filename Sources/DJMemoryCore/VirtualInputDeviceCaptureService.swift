#if os(macOS)
import AppKit
import Foundation

/// App Audio backend that records a verified DJ-software virtual device through
/// `CaptureService`'s AVAudioEngine path. Owns its own `CaptureService` so App Audio
/// never mutates the user's Input Device selection or double-drives that singleton.
public final class VirtualInputDeviceCaptureService: @unchecked Sendable, AppAudioCaptureBackend {
    public let backendKind: AppAudioCaptureBackendKind = .virtualInputDevice
    public var onStreamStopped: ((AppAudioCaptureError) -> Void)?

    public var isMonitoring: Bool { capture.isMonitoring }
    public var isWriting: Bool { capture.isRecording }

    private let capture: CaptureService
    private var boundDevice: AudioInputDevice?
    private var boundSoftwareID = ""

    public init(stagingDirectory: URL = CaptureService.defaultStagingDirectory(), fileManager: FileManager = .default) {
        self.capture = CaptureService(stagingDirectory: stagingDirectory, fileManager: fileManager)
    }

    public func bind(device: AudioInputDevice, softwareID: String) {
        boundDevice = device
        boundSoftwareID = softwareID
    }

    public func listShareableDJApps() async throws -> [MatchedDJApp] {
        let bundleIDs = NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        return DJAppProcessMatcher.matchRunning(bundleIdentifiers: bundleIDs)
    }

    public func startMonitoring(
        bundleIdentifier: String,
        displayName: String,
        prerollSeconds: TimeInterval
    ) async throws {
        _ = bundleIdentifier
        _ = displayName
        _ = prerollSeconds
        guard let device = boundDevice else {
            throw AppAudioCaptureError.engineFailed("No virtual input device is bound for App audio Capture.")
        }
        do {
            try capture.startMonitoring(device: device)
        } catch let error as CaptureServiceError {
            throw mapCaptureError(error)
        }
    }

    public func stopMonitoring() async {
        capture.stopMonitoring()
        boundDevice = nil
        boundSoftwareID = ""
    }

    public func beginRecordingFile() throws {
        do {
            try capture.beginRecordingFile()
        } catch let error as CaptureServiceError {
            throw mapCaptureError(error)
        }
    }

    public func endRecordingFile(discard: Bool) throws -> CaptureResult? {
        let result: CaptureResult?
        do {
            result = try capture.endRecordingFile(discard: discard)
        } catch let error as CaptureServiceError {
            throw mapCaptureError(error)
        }
        guard let result else { return nil }
        let device = boundDevice
        return CaptureResult(
            stagingURL: result.stagingURL,
            deviceID: device?.id ?? result.deviceID,
            deviceName: device?.name ?? result.deviceName,
            startedAt: result.startedAt,
            endedAt: result.endedAt,
            captureRoute: .appAudio,
            captureBackend: .virtualInputDevice,
            deviceTransport: device?.transportType ?? result.deviceTransport
        )
    }

    public func currentInputLevel() -> Float {
        capture.currentInputLevel()
    }

    private func mapCaptureError(_ error: CaptureServiceError) -> AppAudioCaptureError {
        switch error {
        case .permissionDenied:
            return .permissionDenied
        case .deviceMissing:
            let name = boundDevice?.name ?? "virtual audio device"
            return .engineFailed("\(name) is not available as an input. Open the DJ app, then Arm again, or use Process Audio Tap / folder Protection.")
        case .diskFull:
            return .diskFull
        case .engineFailed(let detail):
            return .engineFailed(detail)
        case .alreadyRecording:
            return isWriting ? .alreadyWriting : .alreadyMonitoring
        case .notRecording:
            return isWriting ? .notWriting : .notMonitoring
        }
    }
}
#endif
