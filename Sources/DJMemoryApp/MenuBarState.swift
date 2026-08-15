import SwiftUI

/// Visual state for the menu bar icon + adjacent label.
/// Derived from AppModel.captureState — see AppModel.menuBarState.
enum MenuBarState: Equatable {
    case launching
    case ready
    case armed(djAppName: String?)
    case capturing(djAppName: String?)
    case saving
    case saved
    case failed(String)

    var symbolName: String {
        switch self {
        case .launching: return "waveform"
        case .ready: return "waveform"
        case .armed: return "waveform.circle.fill"
        case .capturing: return "waveform.circle.fill"
        case .saving: return "arrow.down.circle.fill"
        case .saved: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var tint: Color? {
        switch self {
        case .launching: return nil
        case .ready, .armed: return .yellow
        case .capturing: return .red
        case .saving: return .blue
        case .saved: return .blue
        case .failed: return nil
        }
    }

    /// Text rendered next to the icon in the menu bar, if any.
    var label: String? {
        switch self {
        case .launching, .ready, .saving, .failed: return nil
        case .armed(let name): return name
        case .capturing(let name): return name
        case .saved: return "SAVED"
        }
    }

    var labelColor: Color {
        switch self {
        case .capturing: return .white
        default: return .primary
        }
    }

    var isFlashing: Bool { self == .launching }
    var isPulsing: Bool {
        if case .capturing = self { return true }
        return false
    }

    var accessibilityDescription: String {
        switch self {
        case .launching: return "Starting up"
        case .ready: return "Ready for capture"
        case .armed(let name): return name.map { "\($0) detected, armed" } ?? "Armed"
        case .capturing(let name): return name.map { "Capturing \($0)" } ?? "Capturing"
        case .saving: return "Saving capture"
        case .saved: return "Set saved"
        case .failed(let reason): return "Capture error: \(reason)"
        }
    }
}
