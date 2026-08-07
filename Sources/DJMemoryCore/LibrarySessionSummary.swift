import Foundation

public struct LibrarySessionSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let archive: ArchiveMetadata
    public let matchedTracklist: ImportedTracklist?
    public let context: SetContext

    public init(
        archive: ArchiveMetadata,
        matchedTracklist: ImportedTracklist?,
        context: SetContext? = nil
    ) {
        self.id = archive.id
        self.archive = archive
        self.matchedTracklist = matchedTracklist
        self.context = context ?? SetContext(sessionID: archive.id)
    }

    public var trackCount: Int {
        matchedTracklist?.tracks.count ?? 0
    }
}

public struct LibrarySessionMatcher {
    public init() {}

    public func summaries(
        archives: [ArchiveMetadata],
        importedTracklists: [ImportedTracklist],
        setContexts: [SetContext] = []
    ) -> [LibrarySessionSummary] {
        archives.map { archive in
            let context = setContexts.first { $0.sessionID == archive.id } ?? SetContext(sessionID: archive.id)
            return LibrarySessionSummary(
                archive: archive,
                matchedTracklist: bestMatch(
                    for: archive,
                    context: context,
                    importedTracklists: importedTracklists
                ),
                context: context
            )
        }
    }

    private func bestMatch(
        for archive: ArchiveMetadata,
        context: SetContext,
        importedTracklists: [ImportedTracklist]
    ) -> ImportedTracklist? {
        if let manualTracklistID = context.manualTracklistID {
            return importedTracklists.first { $0.id == manualTracklistID && $0.kind.isMatchableToRecording }
        }

        let candidates = importedTracklists.filter {
            $0.appID == archive.sourceAppID && $0.kind.isMatchableToRecording
        }

        return candidates.min { lhs, rhs in
            abs(lhs.importedAt.timeIntervalSince(archive.detectedAt)) < abs(rhs.importedAt.timeIntervalSince(archive.detectedAt))
        }
    }
}
