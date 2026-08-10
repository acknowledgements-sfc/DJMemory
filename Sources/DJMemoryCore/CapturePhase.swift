import Foundation

public enum CapturePhase: Equatable, Sendable {
    case idle
    case requestingPermission
    case needsScreenRecordingPermission
    case armed
    case watching
    case recording
    case saving
    case failed(String)
}

public struct CaptureUIState: Equatable, Sendable {
    public var mode: CaptureMode
    public var phase: CapturePhase
    public var devices: [AudioInputDevice]
    public var selectedDeviceID: String?
    public var targetApps: [MatchedDJApp]
    public var selectedTargetAppID: String?
    public var inputLevel: Float
    public var lastArchivedSessionID: UUID?
    public var statusMessage: String

    public init(
        mode: CaptureMode = .appAudio,
        phase: CapturePhase = .idle,
        devices: [AudioInputDevice] = [],
        selectedDeviceID: String? = nil,
        targetApps: [MatchedDJApp] = [],
        selectedTargetAppID: String? = nil,
        inputLevel: Float = 0,
        lastArchivedSessionID: UUID? = nil,
        statusMessage: String = "Choose a running DJ app, then arm App audio Capture."
    ) {
        self.mode = mode
        self.phase = phase
        self.devices = devices
        self.selectedDeviceID = selectedDeviceID
        self.targetApps = targetApps
        self.selectedTargetAppID = selectedTargetAppID
        self.inputLevel = inputLevel
        self.lastArchivedSessionID = lastArchivedSessionID
        self.statusMessage = statusMessage
    }

    public var selectedDevice: AudioInputDevice? {
        guard let selectedDeviceID else { return nil }
        return devices.first { $0.id == selectedDeviceID }
    }

    public var selectedTargetApp: MatchedDJApp? {
        guard let selectedTargetAppID else { return nil }
        return targetApps.first { $0.software.id == selectedTargetAppID }
    }

    public var isRecording: Bool {
        if case .recording = phase { return true }
        return false
    }

    public var isWatchingOrRecording: Bool {
        switch phase {
        case .watching, .recording, .saving: return true
        default: return false
        }
    }
}
