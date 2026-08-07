import Foundation

public struct SessionLibrary {
    public let archiveRoot: URL
    private let archiveRootBookmarkData: Data?
    private let fileManager: FileManager

    public init(
        archiveRoot: URL = ArchiveService.defaultArchiveRoot(),
        archiveRootBookmarkData: Data? = nil,
        fileManager: FileManager = .default
    ) {
        self.archiveRoot = archiveRoot
        self.archiveRootBookmarkData = archiveRootBookmarkData
        self.fileManager = fileManager
    }

    public func archivedMetadata() throws -> [ArchiveMetadata] {
        try withSecurityScopedArchiveRoot {
            try archivedMetadataWithAccess()
        }
    }

    private func archivedMetadataWithAccess() throws -> [ArchiveMetadata] {
        guard fileManager.fileExists(atPath: archiveRoot.path) else {
            return []
        }

        let urls = try fileManager.contentsOfDirectory(
            at: archiveRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return urls
            .filter { $0.pathExtension.lowercased() == "json" }
            .compactMap { url -> ArchiveMetadata? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(ArchiveMetadata.self, from: data)
            }
            .sorted { $0.detectedAt > $1.detectedAt }
    }

    private func withSecurityScopedArchiveRoot<T>(_ operation: () throws -> T) rethrows -> T {
        guard let archiveRootBookmarkData else {
            return try operation()
        }

        var isStale = false
        guard
            let url = try? URL(
                resolvingBookmarkData: archiveRootBookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ),
            !isStale
        else {
            return try operation()
        }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }
}
