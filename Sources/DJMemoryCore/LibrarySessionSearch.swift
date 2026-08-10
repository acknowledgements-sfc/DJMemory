import Foundation

public struct LibrarySessionSearch {
    public init() {}

    public func filter(
        _ summaries: [LibrarySessionSummary],
        query: String,
        dateFilter: LibraryDateFilter = .all,
        appDisplayName: (String) -> String,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [LibrarySessionSummary] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return summaries.filter { summary in
            guard dateFilter.contains(summary.archive.detectedAt, calendar: calendar, now: now) else {
                return false
            }
            guard !normalizedQuery.isEmpty else { return true }
            return searchableText(for: summary, appDisplayName: appDisplayName)
                .localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    public func filterTracklists(
        _ tracklists: [ImportedTracklist],
        query: String,
        dateFilter: LibraryDateFilter = .all,
        matchedSetDates: [UUID: Date] = [:],
        appDisplayName: (String) -> String,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> [ImportedTracklist] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return tracklists.filter { tracklist in
            guard tracklistPassesDateFilter(
                tracklist,
                dateFilter: dateFilter,
                matchedSetDate: matchedSetDates[tracklist.id],
                calendar: calendar,
                now: now
            ) else { return false }

            guard !normalizedQuery.isEmpty else { return true }
            return tracklist.sourceURL.lastPathComponent.localizedCaseInsensitiveContains(normalizedQuery)
                || appDisplayName(tracklist.appID).localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    public func tracklistPassesDateFilter(
        _ tracklist: ImportedTracklist,
        dateFilter: LibraryDateFilter,
        matchedSetDate: Date?,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> Bool {
        if case .all = dateFilter { return true }
        if dateFilter.contains(tracklist.importedAt, calendar: calendar, now: now) {
            return true
        }
        if let matchedSetDate, dateFilter.contains(matchedSetDate, calendar: calendar, now: now) {
            return true
        }
        return tracklist.tracks.contains { track in
            guard let playedOn = track.playedOn else { return false }
            return dateFilter.contains(playedOn, calendar: calendar, now: now)
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
