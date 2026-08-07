import Foundation

public enum CapturePhase: Equatable, Sendable {
    case idle
    case requestingPermission
    case armed
    case recording
    case saving
    case failed(String)
}

public struct CaptureUIState: Equatable, Sendable {
    public var phase: CapturePhase
    public var devices: [AudioInputDevice]
    public var selectedDeviceID: String?
    public var inputLevel: Float
    public var lastArchivedSessionID: UUID?
    public var statusMessage: String

    public init(
        phase: CapturePhase = .idle,
        devices: [AudioInputDevice] = [],
        selectedDeviceID: String? = nil,
        inputLevel: Float = 0,
        lastArchivedSessionID: UUID? = nil,
        statusMessage: String = "Choose an input device, then start Capture."
    ) {
        self.phase = phase
        self.devices = devices
        self.selectedDeviceID = selectedDeviceID
        self.inputLevel = inputLevel
        self.lastArchivedSessionID = lastArchivedSessionID
        self.statusMessage = statusMessage
    }

    public var selectedDevice: AudioInputDevice? {
        guard let selectedDeviceID else { return nil }
        return devices.first { $0.id == selectedDeviceID }
    }

    public var isRecording: Bool {
        if case .recording = phase { return true }
        return false
    }
}
