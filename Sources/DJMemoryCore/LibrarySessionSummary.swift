import Foundation

public struct LibrarySessionSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let archive: ArchiveMetadata
    public let matchedTracklist: ImportedTracklist?

    public init(archive: ArchiveMetadata, matchedTracklist: ImportedTracklist?) {
        self.id = archive.id
        self.archive = archive
        self.matchedTracklist = matchedTracklist
    }

    public var trackCount: Int {
        matchedTracklist?.tracks.count ?? 0
    }
}

public struct LibrarySessionMatcher {
    public init() {}

    public func summaries(
        archives: [ArchiveMetadata],
        importedTracklists: [ImportedTracklist]
    ) -> [LibrarySessionSummary] {
        archives.map { archive in
            LibrarySessionSummary(
                archive: archive,
                matchedTracklist: bestMatch(for: archive, importedTracklists: importedTracklists)
            )
        }
    }

    private func bestMatch(for archive: ArchiveMetadata, importedTracklists: [ImportedTracklist]) -> ImportedTracklist? {
        let candidates = importedTracklists.filter {
            $0.appID == archive.sourceAppID && $0.kind.isMatchableToRecording
        }

        return candidates.min { lhs, rhs in
            abs(lhs.importedAt.timeIntervalSince(archive.detectedAt)) < abs(rhs.importedAt.timeIntervalSince(archive.detectedAt))
        }
    }
}
