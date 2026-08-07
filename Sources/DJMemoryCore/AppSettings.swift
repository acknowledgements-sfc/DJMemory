import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
    public let automaticScanningEnabled: Bool
    public let scanIntervalSeconds: Int

    public init(
        automaticScanningEnabled: Bool = true,
        scanIntervalSeconds: Int = 60
    ) {
        self.automaticScanningEnabled = automaticScanningEnabled
        self.scanIntervalSeconds = scanIntervalSeconds
    }

    public static let `default` = AppSettings()
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
