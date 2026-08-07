import Foundation

/// Per-app setup tile state (HANDOFF G5). Display names are load-bearing copy.
public enum AppSetupState: String, Equatable, Sendable, CaseIterable {
    case watching
    case saving
    case recordingDetected
    case archived
    case needsFolderAccess
    case appNotFound
    case attentionNeeded
    case error

    public var displayName: String {
        switch self {
        case .watching:
            return "Watching"
        case .saving:
            return "Saving"
        case .recordingDetected:
            return "Recording Detected"
        case .archived:
            return "Archived"
        case .needsFolderAccess:
            return "Needs folder access"
        case .appNotFound:
            return "App not found"
        case .attentionNeeded:
            return "Attention Needed"
        case .error:
            return "Error"
        }
    }

    public var toneKind: String {
        switch self {
        case .watching, .archived:
            return "ok"
        case .saving:
            return "info"
        case .recordingDetected, .needsFolderAccess, .appNotFound:
            return "warn"
        case .attentionNeeded, .error:
            return "danger"
        }
    }
}
