import Foundation

public enum ArchiveServiceError: Error, Equatable {
    case sourceFileMissing(URL)
    case sourceIsDirectory(URL)
    case archiveDirectoryUnavailable(URL)
}

public struct ArchiveService {
    public let archiveRoot: URL
    private let fileManager: FileManager
    private let calendar: Calendar

    public init(
        archiveRoot: URL = Self.defaultArchiveRoot(),
        fileManager: FileManager = .default,
        calendar: Calendar = .current
    ) {
        self.archiveRoot = archiveRoot
        self.fileManager = fileManager
        self.calendar = calendar
    }

    public static func defaultArchiveRoot() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Music", isDirectory: true)
            .appendingPathComponent("DJMemory", isDirectory: true)
    }

    @discardableResult
    public func archive(sourceURL: URL, sourceAppID: String, detectedAt: Date = Date()) throws -> RecordingSession {
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

        try writeMetadata(for: session, originalFilename: sourceURL.lastPathComponent)
        return session
    }

    public func metadataURL(for archiveURL: URL) -> URL {
        archiveURL.deletingPathExtension().appendingPathExtension("json")
    }

    public func isSourceAlreadyArchived(_ sourceURL: URL) -> Bool {
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

        return metadataURLs
            .filter { $0.pathExtension.lowercased() == "json" }
            .contains { metadataURL in
                guard
                    let data = try? Data(contentsOf: metadataURL),
                    let metadata = try? decoder.decode(ArchiveMetadata.self, from: data)
                else {
                    return false
                }

                return metadata.sourcePath == sourcePath
            }
    }

    private func writeMetadata(for session: RecordingSession, originalFilename: String) throws {
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
            durationSeconds: nil
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(metadata)
        try data.write(to: metadataURL(for: archiveURL), options: [.atomic])
    }

    private func uniqueDestinationURL(for sourceURL: URL, sourceAppID: String, detectedAt: Date) -> URL {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd HHmm"

        let appName = SupportedDJSoftware.all.first { $0.id == sourceAppID }?.displayName ?? sourceAppID
        let safeAppName = sanitizeFilenameComponent(appName)
        let ext = sourceURL.pathExtension
        let baseName = "\(formatter.string(from: detectedAt)) - \(safeAppName) - Set"

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
}
