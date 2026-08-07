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

    public init(
        automaticScanningEnabled: Bool = true,
        scanIntervalSeconds: Int = 60,
        archiveNamingTemplate: String = Self.defaultArchiveNamingTemplate,
        archiveRootPath: String? = nil,
        archiveRootBookmarkData: Data? = nil,
        hasCompletedOnboarding: Bool = false,
        verifyCopies: Bool = true,
        notifyAfterArchiving: Bool = true,
        launchAtLogin: Bool = false
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
    }

    public static let `default` = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case automaticScanningEnabled
        case scanIntervalSeconds
        case archiveNamingTemplate
        case archiveRootPath
        case archiveRootBookmarkData
        case hasCompletedOnboarding
        case verifyCopies
        case notifyAfterArchiving
        case launchAtLogin
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        automaticScanningEnabled = try container.decodeIfPresent(Bool.self, forKey: .automaticScanningEnabled) ?? true
        scanIntervalSeconds = try container.decodeIfPresent(Int.self, forKey: .scanIntervalSeconds) ?? 60
        archiveNamingTemplate = try container.decodeIfPresent(String.self, forKey: .archiveNamingTemplate)
            ?? Self.defaultArchiveNamingTemplate
        archiveRootPath = try container.decodeIfPresent(String.self, forKey: .archiveRootPath)
        archiveRootBookmarkData = try container.decodeIfPresent(Data.self, forKey: .archiveRootBookmarkData)
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        verifyCopies = try container.decodeIfPresent(Bool.self, forKey: .verifyCopies) ?? true
        notifyAfterArchiving = try container.decodeIfPresent(Bool.self, forKey: .notifyAfterArchiving) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
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
        launchAtLogin: Bool? = nil
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
            launchAtLogin: launchAtLogin ?? self.launchAtLogin
        )
    }
}

public struct AppSettingsStore {
    public let storageURL: URL
    private let fileManager: FileManager

    public init(
        storageURL: URL = Self.defaultStorageURL(),
        fileManager: FileManager = .default
    ) {
        self.storageURL = storageURL
        self.fileManager = fileManager
    }

    public static func defaultStorageURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("DJMemory", isDirectory: true)
            .appendingPathComponent("settings.json")
    }

    public func load() throws -> AppSettings {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return .default
        }

        let data = try Data(contentsOf: storageURL)
        return try JSONDecoder().decode(AppSettings.self, from: data)
    }

    public func save(_ settings: AppSettings) throws {
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: storageURL, options: [.atomic])
    }
}
