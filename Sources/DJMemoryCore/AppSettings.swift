import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultArchiveNamingTemplate = "{date} {time} - {app} - Set"

    public let automaticScanningEnabled: Bool
    public let scanIntervalSeconds: Int
    public let archiveNamingTemplate: String
    public let archiveRootPath: String?
    public let archiveRootBookmarkData: Data?
    public let hasCompletedOnboarding: Bool
    public let verifyCopies: Bool
    public let notifyAfterArchiving: Bool
    public let launchAtLogin: Bool
    public let lastCaptureDeviceID: String?
    public let cloudSyncEnabled: Bool
    public let cloudArchiveBackupEnabled: Bool

    public init(
        automaticScanningEnabled: Bool = true,
        scanIntervalSeconds: Int = 60,
        archiveNamingTemplate: String = Self.defaultArchiveNamingTemplate,
        archiveRootPath: String? = nil,
        archiveRootBookmarkData: Data? = nil,
        hasCompletedOnboarding: Bool = false,
        verifyCopies: Bool = true,
        notifyAfterArchiving: Bool = true,
        launchAtLogin: Bool = false,
        lastCaptureDeviceID: String? = nil,
        cloudSyncEnabled: Bool = false,
        cloudArchiveBackupEnabled: Bool = false
    ) {
        self.automaticScanningEnabled = automaticScanningEnabled
        self.scanIntervalSeconds = scanIntervalSeconds
        self.archiveNamingTemplate = archiveNamingTemplate
        self.archiveRootPath = archiveRootPath
        self.archiveRootBookmarkData = archiveRootBookmarkData
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.verifyCopies = verifyCopies
        self.notifyAfterArchiving = notifyAfterArchiving
        self.launchAtLogin = launchAtLogin
        self.lastCaptureDeviceID = lastCaptureDeviceID
        self.cloudSyncEnabled = cloudSyncEnabled
        self.cloudArchiveBackupEnabled = cloudArchiveBackupEnabled
    }

    public static let `default` = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case automaticScanningEnabled, scanIntervalSeconds, archiveNamingTemplate
        case archiveRootPath, archiveRootBookmarkData, hasCompletedOnboarding
        case verifyCopies, notifyAfterArchiving, launchAtLogin
        case lastCaptureDeviceID, cloudSyncEnabled, cloudArchiveBackupEnabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        automaticScanningEnabled = try c.decodeIfPresent(Bool.self, forKey: .automaticScanningEnabled) ?? true
        scanIntervalSeconds = try c.decodeIfPresent(Int.self, forKey: .scanIntervalSeconds) ?? 60
        archiveNamingTemplate = try c.decodeIfPresent(String.self, forKey: .archiveNamingTemplate) ?? Self.defaultArchiveNamingTemplate
        archiveRootPath = try c.decodeIfPresent(String.self, forKey: .archiveRootPath)
        archiveRootBookmarkData = try c.decodeIfPresent(Data.self, forKey: .archiveRootBookmarkData)
        hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        verifyCopies = try c.decodeIfPresent(Bool.self, forKey: .verifyCopies) ?? true
        notifyAfterArchiving = try c.decodeIfPresent(Bool.self, forKey: .notifyAfterArchiving) ?? true
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        lastCaptureDeviceID = try c.decodeIfPresent(String.self, forKey: .lastCaptureDeviceID)
        cloudSyncEnabled = try c.decodeIfPresent(Bool.self, forKey: .cloudSyncEnabled) ?? false
        cloudArchiveBackupEnabled = try c.decodeIfPresent(Bool.self, forKey: .cloudArchiveBackupEnabled) ?? false
    }

    public func updating(
        automaticScanningEnabled: Bool? = nil,
        scanIntervalSeconds: Int? = nil,
        archiveNamingTemplate: String? = nil,
        archiveRootPath: String?? = nil,
        archiveRootBookmarkData: Data?? = nil,
        hasCompletedOnboarding: Bool? = nil,
        verifyCopies: Bool? = nil,
        notifyAfterArchiving: Bool? = nil,
        launchAtLogin: Bool? = nil,
        lastCaptureDeviceID: String?? = nil,
        cloudSyncEnabled: Bool? = nil,
        cloudArchiveBackupEnabled: Bool? = nil
    ) -> AppSettings {
        AppSettings(
            automaticScanningEnabled: automaticScanningEnabled ?? self.automaticScanningEnabled,
            scanIntervalSeconds: scanIntervalSeconds ?? self.scanIntervalSeconds,
            archiveNamingTemplate: archiveNamingTemplate ?? self.archiveNamingTemplate,
            archiveRootPath: archiveRootPath ?? self.archiveRootPath,
            archiveRootBookmarkData: archiveRootBookmarkData ?? self.archiveRootBookmarkData,
            hasCompletedOnboarding: hasCompletedOnboarding ?? self.hasCompletedOnboarding,
            verifyCopies: verifyCopies ?? self.verifyCopies,
            notifyAfterArchiving: notifyAfterArchiving ?? self.notifyAfterArchiving,
            launchAtLogin: launchAtLogin ?? self.launchAtLogin,
            lastCaptureDeviceID: lastCaptureDeviceID ?? self.lastCaptureDeviceID,
            cloudSyncEnabled: cloudSyncEnabled ?? self.cloudSyncEnabled,
            cloudArchiveBackupEnabled: cloudArchiveBackupEnabled ?? self.cloudArchiveBackupEnabled
        )
    }
}

public struct AppSettingsStore {
    public let storageURL: URL
    private let fileManager: FileManager

    public init(storageURL: URL = Self.defaultStorageURL(), fileManager: FileManager = .default) {
        self.storageURL = storageURL
        self.fileManager = fileManager
    }

    public static func defaultStorageURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/DJMemory/settings.json")
    }

    public func load() throws -> AppSettings {
        guard fileManager.fileExists(atPath: storageURL.path) else { return .default }
        return try JSONDecoder().decode(AppSettings.self, from: Data(contentsOf: storageURL))
    }

    public func save(_ settings: AppSettings) throws {
        try fileManager.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(settings).write(to: storageURL, options: [.atomic])
    }
}
