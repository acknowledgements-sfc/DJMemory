import Foundation
import DJMemoryCore

/// Mobile DJ adapters for the iPad companion. Honest Manual Setup labels only.
public enum MobileDJSoftware: String, CaseIterable, Identifiable, Sendable {
    case djay
    case capture

    public var id: String {
        switch self {
        case .djay: return "djay"
        case .capture: return SupportedDJSoftware.captureAppID
        }
    }

    public var displayName: String {
        switch self {
        case .djay: return "djay"
        case .capture: return "DJMemory Capture"
        }
    }

    public var supportLabel: String {
        switch self {
        case .djay: return "Manual Setup"
        case .capture: return "Manual Setup"
        }
    }

    public var guidance: String {
        switch self {
        case .djay:
            return "Recordings often appear under Files → On My iPad → djay. Pick those files here, or Share → Save to DJMemory. Streaming mixes may not be recordable — if import fails, that is why."
        case .capture:
            return "Parallel capture records this iPad’s input while you DJ in another app. It does not watch other apps in the background."
        }
    }

    public static func displayName(for appID: String) -> String {
        allCases.first { $0.id == appID }?.displayName
            ?? SupportedDJSoftware.all.first { $0.id == appID }?.displayName
            ?? appID
    }
}
