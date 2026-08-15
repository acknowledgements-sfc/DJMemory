import Foundation

public struct LibrarySessionSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let archive: ArchiveMetadata
    public let hardwareBackup: ArchiveMetadata?
    public let matchedTracklist: ImportedTracklist?
    public let context: SetContext

    public init(
        archive: ArchiveMetadata,
        matchedTracklist: ImportedTracklist?,
        context: SetContext? = nil,
        hardwareBackup: ArchiveMetadata? = nil,
        id: UUID? = nil
    ) {
        self.id = id ?? archive.id
        self.archive = archive
        self.hardwareBackup = hardwareBackup
        self.matchedTracklist = matchedTracklist
        self.context = context ?? SetContext(sessionID: id ?? archive.id)
    }

    public var trackCount: Int {
        matchedTracklist?.tracks.count ?? 0
    }

    public var performanceDate: Date {
        min(archive.detectedAt, hardwareBackup?.detectedAt ?? archive.detectedAt)
    }

    public func relatedActivity(in events: [ActivityEvent]) -> [ActivityEvent] {
        events.filter { event in
            let detail = event.detail ?? ""
            if detail.contains(archive.originalFilename)
                || detail.contains(archive.archivePath)
                || detail.contains(archive.sourcePath) {
                return true
            }
            guard let backup = hardwareBackup else { return false }
            return detail.contains(backup.originalFilename)
                || detail.contains(backup.archivePath)
                || detail.contains(backup.sourcePath)
        }
    }
}

public struct LibrarySessionMatcher {
    public init() {}

    public static let hardwareCaptureAppIDs: Set<String> = [
        SupportedDJSoftware.captureAppID,
        SupportedDJSoftware.pioneerHardwareAppID
    ]

    public static let hardwareRelatedTracklistAppIDs: Set<String> = [
        SupportedDJSoftware.captureAppID,
        SupportedDJSoftware.pioneerHardwareAppID,
        "rekordbox"
    ]

    public static let captureMatchWindowSeconds: TimeInterval = 6 * 60 * 60

    public func summaries(
        archives: [ArchiveMetadata],
        importedTracklists: [ImportedTracklist],
        setContexts: [SetContext] = []
    ) -> [LibrarySessionSummary] {
        PerformanceSessionLinker.groups(from: archives).map { group in
            let context = setContexts.first { $0.sessionID == group.id } ?? SetContext(sessionID: group.id)
            return LibrarySessionSummary(
                archive: group.primary,
                matchedTracklist: bestMatch(
                    for: group.primary,
                    context: context,
                    importedTracklists: importedTracklists
                ),
                context: context,
                hardwareBackup: group.hardwareBackup,
                id: group.id
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

        let candidates: [ImportedTracklist]
        if Self.hardwareCaptureAppIDs.contains(archive.sourceAppID) {
            // A hardware Capture / Pioneer recording carries no app identity of
            // its own — its tracklist can be a history export from *any* DJ app
            // running at the time. Match the nearest matchable export inside the
            // window rather than restricting to a fixed app list, so a late
            // Serato/Traktor/VirtualDJ export can attach and a closer export can
            // upgrade an earlier auto-match.
            candidates = importedTracklists.filter { tracklist in
                tracklist.kind.isMatchableToRecording
                    && abs(tracklist.importedAt.timeIntervalSince(archive.detectedAt)) <= Self.captureMatchWindowSeconds
            }
        } else {
            candidates = importedTracklists.filter {
                $0.appID == archive.sourceAppID && $0.kind.isMatchableToRecording
            }
        }

        return candidates.min { lhs, rhs in
            abs(lhs.importedAt.timeIntervalSince(archive.detectedAt)) < abs(rhs.importedAt.timeIntervalSince(archive.detectedAt))
        }
    }
}
