import Foundation

public struct LibraryStatistics: Equatable, Sendable {
    public let totalDurationSeconds: Double
    public let totalFileSize: Int64
    public let setsThisMonth: Int
    public let unmatchedCount: Int
    /// Consecutive ISO weeks with ≥1 archive. Nil when streak is zero / no archives.
    public let consecutiveWeeksRunning: Int?

    public init(
        totalDurationSeconds: Double,
        totalFileSize: Int64,
        setsThisMonth: Int,
        unmatchedCount: Int,
        consecutiveWeeksRunning: Int?
    ) {
        self.totalDurationSeconds = totalDurationSeconds
        self.totalFileSize = totalFileSize
        self.setsThisMonth = setsThisMonth
        self.unmatchedCount = unmatchedCount
        self.consecutiveWeeksRunning = consecutiveWeeksRunning
    }
}

public enum LibraryStatisticsCalculator {
    public static func calculate(
        archives: [ArchiveMetadata],
        summaries: [LibrarySessionSummary],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> LibraryStatistics {
        let totalDuration = archives.reduce(0.0) { $0 + ($1.durationSeconds ?? 0) }
        let totalSize = archives.reduce(Int64(0)) { $0 + $1.fileSize }
        let month = calendar.dateComponents([.year, .month], from: now)
        let setsThisMonth = archives.filter {
            let c = calendar.dateComponents([.year, .month], from: $0.detectedAt)
            return c.year == month.year && c.month == month.month
        }.count
        let unmatched = summaries.filter { $0.matchedTracklist == nil }.count
        let streak = consecutiveWeeks(archives: archives, now: now, calendar: calendar)

        return LibraryStatistics(
            totalDurationSeconds: totalDuration,
            totalFileSize: totalSize,
            setsThisMonth: setsThisMonth,
            unmatchedCount: unmatched,
            consecutiveWeeksRunning: streak
        )
    }

    private static func consecutiveWeeks(
        archives: [ArchiveMetadata],
        now: Date,
        calendar: Calendar
    ) -> Int? {
        guard !archives.isEmpty else { return nil }

        var cal = calendar
        cal.firstWeekday = 2 // ISO-ish Monday start when possible
        let weekOfYear = { (date: Date) -> DateComponents in
            cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        }

        let archiveWeeks = Set(archives.map { weekOfYear($0.detectedAt) })
        var cursor = weekOfYear(now)

        // If current week has no archive, start from previous week.
        if !archiveWeeks.contains(cursor) {
            guard let previous = cal.date(byAdding: .weekOfYear, value: -1, to: now) else {
                return nil
            }
            cursor = weekOfYear(previous)
            if !archiveWeeks.contains(cursor) {
                return nil
            }
        }

        var streak = 0
        var probeDate = now
        if !archiveWeeks.contains(weekOfYear(now)) {
            probeDate = cal.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        }

        while true {
            let components = weekOfYear(probeDate)
            if archiveWeeks.contains(components) {
                streak += 1
                guard let previous = cal.date(byAdding: .weekOfYear, value: -1, to: probeDate) else {
                    break
                }
                probeDate = previous
            } else {
                break
            }
        }

        return streak > 0 ? streak : nil
    }
}
