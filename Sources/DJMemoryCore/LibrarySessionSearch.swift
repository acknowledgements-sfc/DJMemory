import Foundation

public struct LibrarySessionSearch {
    public init() {}

    public func filter(
        _ summaries: [LibrarySessionSummary],
        query: String,
        appDisplayName: (String) -> String
    ) -> [LibrarySessionSummary] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return summaries
        }

        return summaries.filter { summary in
            searchableText(for: summary, appDisplayName: appDisplayName)
                .localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    private func searchableText(
        for summary: LibrarySessionSummary,
        appDisplayName: (String) -> String
    ) -> String {
        var values = [
            summary.archive.originalFilename,
            summary.archive.sourceAppID,
            appDisplayName(summary.archive.sourceAppID),
            summary.archive.sourcePath,
            summary.archive.archivePath,
            summary.context.eventName,
            summary.context.venue,
            summary.context.city,
            summary.context.tags,
            summary.context.notes
        ]

        if let matchedTracklist = summary.matchedTracklist {
            values.append(matchedTracklist.sourceURL.lastPathComponent)
            values.append(contentsOf: matchedTracklist.tracks.flatMap { [$0.artist, $0.title, $0.startTime ?? ""] })
        }

        return values.joined(separator: "\n")
    }
}
