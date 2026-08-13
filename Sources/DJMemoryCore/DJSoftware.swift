import Foundation

public enum IntegrationDepth: String, Codable, Sendable {
    case fileWatcher
    case exportImport
    case localControl
    case plugin
}

public enum IntegrationSupportStatus: String, Codable, Sendable {
    case supported
    case partial
    case manualSetup
    case research

    public var displayName: String {
        switch self {
        case .supported:
            return "Supported"
        case .partial:
            return "Partial"
        case .manualSetup:
            return "Manual Setup"
        case .research:
            return "Research"
        }
    }
}

public struct DJSoftware: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let bundleIdentifiers: [String]
    public let defaultRecordingPaths: [String]
    public let defaultHistoryPaths: [String]
    public let integrationDepth: IntegrationDepth
    public let supportStatus: IntegrationSupportStatus
    public let notes: String

    public init(
        id: String,
        displayName: String,
        bundleIdentifiers: [String],
        defaultRecordingPaths: [String],
        defaultHistoryPaths: [String],
        integrationDepth: IntegrationDepth,
        supportStatus: IntegrationSupportStatus,
        notes: String
    ) {
        self.id = id
        self.displayName = displayName
        self.bundleIdentifiers = bundleIdentifiers
        self.defaultRecordingPaths = defaultRecordingPaths
        self.defaultHistoryPaths = defaultHistoryPaths
        self.integrationDepth = integrationDepth
        self.supportStatus = supportStatus
        self.notes = notes
    }
}

public enum SupportedDJSoftware {
    public static let all: [DJSoftware] = [
        DJSoftware(
            id: "serato",
            displayName: "Serato DJ Pro",
            bundleIdentifiers: ["com.serato.seratodj", "com.serato.dj"],
            defaultRecordingPaths: ["~/Music/_Serato_/Recording"],
            defaultHistoryPaths: ["~/Music/_Serato_/History Export"],
            integrationDepth: .exportImport,
            supportStatus: .supported,
            notes: "Strong file-watcher candidate; history exports are user-visible, direct control is not public."
        ),
        DJSoftware(
            id: "rekordbox",
            displayName: "rekordbox",
            bundleIdentifiers: ["com.pioneerdj.rekordboxdj", "com.pioneerdj.rekordbox"],
            defaultRecordingPaths: [],
            defaultHistoryPaths: [],
            integrationDepth: .exportImport,
            supportStatus: .supported,
            notes: "Needs user-selected recording/history folders; XML bridge is documented. Bundle ID is shared by rekordbox 6 and 7."
        ),
        DJSoftware(
            id: "djay",
            displayName: "djay Pro",
            bundleIdentifiers: [
                "com.algoriddim.djay-iphone-free",
                "com.algoriddim.direct.djay-pro-2-mac",
                "com.algoriddim.djay-iphone-free-mac",
                "com.algoriddim.djay-pro-mac"
            ],
            defaultRecordingPaths: ["~/Music/djay/Recordings", "~/Music/djay Pro 2/Recordings"],
            defaultHistoryPaths: [],
            integrationDepth: .fileWatcher,
            supportStatus: .manualSetup,
            notes: "Recording folders have documented defaults, but history/session metadata still needs verification."
        ),
        DJSoftware(
            id: "virtualdj",
            displayName: "VirtualDJ",
            bundleIdentifiers: ["com.atomixproductions.virtualdj"],
            defaultRecordingPaths: ["~/Documents/VirtualDJ"],
            defaultHistoryPaths: ["~/Documents/VirtualDJ/History", "~/Documents/VirtualDJ/DJMemoryDrop"],
            integrationDepth: .localControl,
            supportStatus: .partial,
            notes: "Best candidate for deeper integration via SDK/plugin or Network Control. Native plugin (M14) writes JSONL events into ~/Documents/VirtualDJ/DJMemoryDrop."
        ),
        DJSoftware(
            id: "traktor",
            displayName: "Traktor",
            bundleIdentifiers: ["com.native-instruments.Traktor", "com.native-instruments.tmnt"],
            defaultRecordingPaths: ["~/Music/Traktor/Recordings"],
            defaultHistoryPaths: ["~/Documents/Native Instruments/Traktor*/History"],
            integrationDepth: .exportImport,
            supportStatus: .supported,
            notes: "History playlists and recordings have known default locations for Traktor Pro; Traktor DJ 2 is detected via bundle ID but recording paths still need confirmation."
        ),
        DJSoftware(
            id: "djmemory-capture",
            displayName: "DJMemory Capture",
            bundleIdentifiers: [],
            defaultRecordingPaths: [],
            defaultHistoryPaths: [],
            integrationDepth: .fileWatcher,
            supportStatus: .manualSetup,
            notes: "App audio Capture prefers Process Audio Tap on macOS 14.2+ and falls back to ScreenCaptureKit. ScreenCaptureKit is verified with Serato, rekordbox, djay, VirtualDJ, and Traktor DJ 2; Process Audio Tap still needs live meter+archive PASS. Input device Capture remains available for DJM USB / mixer paths. Twitch Live Playlist, SSL-API, and Traktor QML CSI patches are research-only while sandboxed."
        ),
        DJSoftware(
            id: "pioneer-hardware",
            displayName: "Pioneer Hardware",
            bundleIdentifiers: [],
            defaultRecordingPaths: [],
            defaultHistoryPaths: [],
            integrationDepth: .fileWatcher,
            supportStatus: .manualSetup,
            notes: "Watch USB MASTER REC folders (PIONEERREC / RECxxx.WAV). CDJs need a DJM or all-in-one REC path."
        )
    ]

    public static let captureAppID = "djmemory-capture"
    public static let pioneerHardwareAppID = "pioneer-hardware"
}
