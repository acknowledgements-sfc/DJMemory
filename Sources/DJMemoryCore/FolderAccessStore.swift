import Foundation

public struct FolderAccessStore {
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
            .appendingPathComponent("folder-access.json")
    }

    public func all() throws -> [FolderAccess] {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return []
        }

        let data = try Data(contentsOf: storageURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FolderAccess].self, from: data)
    }

    public func folder(appID: String, kind: FolderKind) throws -> FolderAccess? {
        try all().first { $0.appID == appID && $0.kind == kind }
    }

    public func save(_ access: FolderAccess) throws {
        var records = try all()
        records.removeAll { $0.appID == access.appID && $0.kind == access.kind }
        records.append(access)
        try write(records)
    }

    public func remove(appID: String, kind: FolderKind) throws {
        var records = try all()
        records.removeAll { $0.appID == appID && $0.kind == kind }
        try write(records)
    }

    public func makeBookmarkData(for url: URL) throws -> Data {
        try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    public func resolve(_ access: FolderAccess) -> URL {
        guard let bookmarkData = access.bookmarkData else {
            return access.url
        }

        var isStale = false

        if let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ), !isStale {
            return url
        }

        return access.url
    }

    /// Resolve the bookmark, then check the path still exists as a directory (HANDOFF G3).
    public func isReachable(_ access: FolderAccess) -> Bool {
        let url = resolve(access)
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func write(_ records: [FolderAccess]) throws {
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records.sorted { $0.createdAt < $1.createdAt })
        try data.write(to: storageURL, options: [.atomic])
    }
}
