import Foundation
import CryptoKit

public enum ArchiveServiceError: Error, Equatable {
    case sourceFileMissing(URL)
    case sourceIsDirectory(URL)
    case archiveDirectoryUnavailable(URL)
}

public struct ArchiveService {
    public static let defaultNamingTemplate = AppSettings.defaultArchiveNamingTemplate

    public let archiveRoot: URL
    private let fileManager: FileManager
    private let calendar: Calendar
    private let durationReader: any AudioDurationReading
    private let namingTemplate: String
    private let archiveRootBookmarkData: Data?

    public init(
        archiveRoot: URL = Self.defaultArchiveRoot(),
        fileManager: FileManager = .default,
        calendar: Calendar = .current,
        durationReader: any AudioDurationReading = AudioDurationReader(),
        namingTemplate: String = Self.defaultNamingTemplate,
        archiveRootBookmarkData: Data? = nil
    ) {
        self.archiveRoot = archiveRoot
        self.fileManager = fileManager
        self.calendar = calendar
        self.durationReader = durationReader
        self.namingTemplate = namingTemplate
        self.archiveRootBookmarkData = archiveRootBookmarkData
    }

    public static func defaultArchiveRoot() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Music", isDirectory: true)
            .appendingPathComponent("DJMemory", isDirectory: true)
    }

    @discardableResult
    public func archive(sourceURL: URL, sourceAppID: String, detectedAt: Date = Date()) throws -> RecordingSession {
        try withSecurityScopedArchiveRoot {
            try archiveWithAccess(sourceURL: sourceURL, sourceAppID: sourceAppID, detectedAt: detectedAt)
        }
    }

    private func archiveWithAccess(sourceURL: URL, sourceAppID: String, detectedAt: Date) throws -> RecordingSession {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory) else {
            throw ArchiveServiceError.sourceFileMissing(sourceURL)
        }

        guard !isDirectory.boolValue else {
            throw ArchiveServiceError.sourceIsDirectory(sourceURL)
        }

        try fileManager.createDirectory(at: archiveRoot, withIntermediateDirectories: true)

        guard fileManager.fileExists(atPath: archiveRoot.path) else {
            throw ArchiveServiceError.archiveDirectoryUnavailable(archiveRoot)
        }

        let fileSize = try sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let sourceFingerprint = try contentFingerprint(for: sourceURL)
        let destinationURL = uniqueDestinationURL(for: sourceURL, sourceAppID: sourceAppID, detectedAt: detectedAt)

        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        let session = RecordingSession(
            sourceAppID: sourceAppID,
            detectedAt: detectedAt,
            completedAt: Date(),
            sourceURL: sourceURL,
            archiveURL: destinationURL,
            fileSize: Int64(fileSize),
            status: .archived
        )

        try writeMetadata(
            for: session,
            originalFilename: sourceURL.lastPathComponent,
            sourceFingerprint: sourceFingerprint
        )
        return session
    }

    public func metadataURL(for archiveURL: URL) -> URL {
        archiveURL.deletingPathExtension().appendingPathExtension("json")
    }

    public func isSourceAlreadyArchived(_ sourceURL: URL) -> Bool {
        withSecurityScopedArchiveRoot {
            isSourceAlreadyArchivedWithAccess(sourceURL)
        }
    }

    private func isSourceAlreadyArchivedWithAccess(_ sourceURL: URL) -> Bool {
        guard let metadataURLs = try? fileManager.contentsOfDirectory(
            at: archiveRoot,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sourcePath = sourceURL.path
        let sourceFileSize = (try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init)
        var sourceFingerprint: String?

        return metadataURLs
            .filter { $0.pathExtension.lowercased() == "json" }
            .contains { metadataURL in
                guard
                    let data = try? Data(contentsOf: metadataURL),
                    let metadata = try? decoder.decode(ArchiveMetadata.self, from: data)
                else {
                    return false
                }

                if metadata.sourcePath == sourcePath {
                    return true
                }

                guard
                    let sourceFileSize,
                    let metadataFingerprint = metadata.sourceFingerprint
                else {
                    return false
                }

                if sourceFingerprint == nil {
                    sourceFingerprint = try? contentFingerprint(for: sourceURL)
                }

                guard let sourceFingerprint else {
                    return false
                }

                return metadata.fileSize > 0
                    && metadata.fileSize == sourceFileSize
                    && metadataFingerprint == sourceFingerprint
            }
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

    private func writeMetadata(for session: RecordingSession, originalFilename: String, sourceFingerprint: String) throws {
        guard let archiveURL = session.archiveURL else { return }

        let metadata = ArchiveMetadata(
            sessionID: session.id,
            sourceAppID: session.sourceAppID,
            detectedAt: session.detectedAt,
            completedAt: session.completedAt,
            sourcePath: session.sourceURL.path,
            archivePath: archiveURL.path,
            fileSize: session.fileSize ?? 0,
            originalFilename: originalFilename,
            durationSeconds: durationReader.durationSeconds(for: archiveURL),
            sourceFingerprint: sourceFingerprint
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        try data.write(to: metadataURL(for: archiveURL), options: [.atomic])
    }

    private func uniqueDestinationURL(for sourceURL: URL, sourceAppID: String, detectedAt: Date) -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.calendar = calendar
        timeFormatter.dateFormat = "HHmm"

        let appName = SupportedDJSoftware.all.first { $0.id == sourceAppID }?.displayName ?? sourceAppID
        let ext = sourceURL.pathExtension
        let renderedName = namingTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? Self.defaultNamingTemplate
            : namingTemplate
        let baseName = sanitizeFilenameComponent(
            renderedName
                .replacingOccurrences(of: "{date}", with: dateFormatter.string(from: detectedAt))
                .replacingOccurrences(of: "{time}", with: timeFormatter.string(from: detectedAt))
                .replacingOccurrences(of: "{app}", with: appName)
                .replacingOccurrences(of: "{source}", with: sourceURL.deletingPathExtension().lastPathComponent)
        )

        var candidate = archiveRoot.appendingPathComponent(baseName).appendingPathExtension(ext)
        var suffix = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = archiveRoot.appendingPathComponent("\(baseName) \(suffix)").appendingPathExtension(ext)
            suffix += 1
        }

        return candidate
    }

    private func sanitizeFilenameComponent(_ value: String) -> String {
        let invalid = CharacterSet(charactersIn: "/:")
        return value.components(separatedBy: invalid).joined(separator: "-")
    }

    private func contentFingerprint(for url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer {
            try? handle.close()
        }

        var hasher = SHA256()

        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            hasher.update(data: chunk)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
