import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultArchiveNamingTemplate = "{date} {time} - {app} - Set"

    public let automaticScanningEnabled: Bool
    public let scanIntervalSeconds: Int
    public let archiveNamingTemplate: String
    public let archiveRootPath: String?
    public let archiveRootBookmarkData: Data?
    public let hasCompletedOnboarding: Bool

    public init(
        automaticScanningEnabled: Bool = true,
        scanIntervalSeconds: Int = 60,
        archiveNamingTemplate: String = Self.defaultArchiveNamingTemplate,
        archiveRootPath: String? = nil,
        archiveRootBookmarkData: Data? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.automaticScanningEnabled = automaticScanningEnabled
        self.scanIntervalSeconds = scanIntervalSeconds
        self.archiveNamingTemplate = archiveNamingTemplate
        self.archiveRootPath = archiveRootPath
        self.archiveRootBookmarkData = archiveRootBookmarkData
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public static let `default` = AppSettings()

    private enum CodingKeys: String, CodingKey {
        case automaticScanningEnabled
        case scanIntervalSeconds
        case archiveNamingTemplate
        case archiveRootPath
        case archiveRootBookmarkData
        case hasCompletedOnboarding
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
