import SwiftUI
import DJMemoryCore

struct HomeDashboardView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            identityBand
            attentionBanners
            lastSetAndGlance
            recentShelf
            topTracksAndActivity
            venuesAndTags
            djAppsSection
            footer
        }
        .frame(maxWidth: 1180, alignment: .leading)
        .accessibilityIdentifier("home.root")
    }

    private var identityBand: some View {
        Panel(padding: 14) {
            HStack(alignment: .top, spacing: 14) {
                monogram
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(greeting)
                            .font(.system(size: DJToken.TypeSize.title, weight: .semibold))
                        Badge(title: model.protectionState.headline, tone: protectionTone)
                        StatusDot(tone: protectionTone, pulse: model.protectionState == .scanning)
                    }
                    Text(metaLine)
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                    Rectangle().fill(DJToken.hairline).frame(height: 1).padding(.vertical, 4)
                    Text(adaptiveSentence)
                        .font(.system(size: DJToken.TypeSize.body))
                        .foregroundStyle(DJToken.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                VStack(spacing: 8) {
                    Button {
                        model.scanNow()
                    } label: {
                        Label(model.isScanning ? "Scanning…" : "Scan Now", systemImage: "waveform.badge.magnifyingglass")
                    }
                    .buttonStyle(DJPrimaryButtonStyle())
                    .disabled(model.isScanning)
                    .accessibilityIdentifier("home.scanNow")

                    Button("Open Library") {
                        model.selectedRoute = .library
                    }
                    .buttonStyle(DJSecondaryButtonStyle())
                    .accessibilityIdentifier("home.openLibrary")
                }
            }
        }
    }

    private var monogram: some View {
        let accent = DJToken.accent(forAppID: model.librarySummaries.first?.archive.sourceAppID ?? "serato")
        return Group {
            if let initials = model.profile.initials {
                Text(initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
            } else {
                Image(systemName: "person")
                    .foregroundStyle(accent)
            }
        }
        .frame(width: 44, height: 44)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: DJToken.Radius.control)
                .stroke(accent.opacity(0.33), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var attentionBanners: some View {
        ForEach(model.unreachableRecordingAccesses(), id: \.id) { access in
            Panel(tone: .danger, padding: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DJToken.danger)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(model.displayName(for: access.appID)) folder is unavailable")
                            .font(.system(size: DJToken.TypeSize.body, weight: .semibold))
                        PathChip(path: access.url.path, tone: .danger)
                        Text("The drive may be unplugged.")
                            .font(.system(size: DJToken.TypeSize.secondary))
                            .foregroundStyle(DJToken.mutedForeground)
                    }
                    Spacer()
                    Button("Fix Folder") {
                        model.selectedRoute = .recovery(access.appID)
                    }
                    .buttonStyle(DJPrimaryButtonStyle())
                    .accessibilityIdentifier("home.fix.\(access.appID)")
                }
            }
        }
    }

    private var lastSetAndGlance: some View {
        HStack(alignment: .top, spacing: 12) {
            lastSetPanel
                .frame(maxWidth: .infinity)
            glanceTiles
                .frame(width: 296)
        }
    }

    @ViewBuilder
    private var lastSetPanel: some View {
        Panel(title: "Your last set", padding: 12) {
            if let summary = model.librarySummaries.sorted(by: { $0.archive.detectedAt > $1.archive.detectedAt }).first {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Badge(title: "Archived & verified", tone: .ok)
                        Spacer()
                        Button("Open in Library") {
                            model.selectedRoute = .library
                        }
                        .buttonStyle(DJGhostButtonStyle())
                    }
                    Text(summary.context.eventName.isEmpty ? summary.archive.originalFilename : summary.context.eventName)
                        .font(.system(size: 15, weight: .semibold))
                    Text(subtitle(for: summary))
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)

                    Waveform(
                        seed: summary.archive.originalFilename,
                        barCount: 88,
                        tint: DJToken.accent(forAppID: summary.archive.sourceAppID)
                    )
                    .frame(height: 56)
                    .padding(8)
                    .background(DJToken.muted, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))

                    HStack {
                        fact("Duration", formatDuration(summary.archive.durationSeconds))
                        fact("Tracks", summary.matchedTracklist == nil ? "—" : "\(summary.trackCount)")
                        fact("Size", ByteCountFormatter.string(fromByteCount: summary.archive.fileSize, countStyle: .file))
                        fact("Tracklist", summary.matchedTracklist == nil ? "Unmatched" : "Matched")
                    }

                    PathChip(path: summary.archive.archivePath)

                    if !summary.context.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Rectangle().fill(DJToken.border).frame(width: 2)
                            Text("“\(summary.context.notes)”")
                                .italic()
                                .font(.system(size: DJToken.TypeSize.body))
                                .foregroundStyle(DJToken.mutedForeground)
                        }
                    }

                    HStack {
                        Button("Reveal in Finder") {
                            model.revealInFinder(URL(fileURLWithPath: summary.archive.archivePath))
                        }
                        .buttonStyle(DJSecondaryButtonStyle())
                        Button("Edit details") {
                            model.selectedRoute = .library
                        }
                        .buttonStyle(DJGhostButtonStyle())
                    }
                }
            } else {
                EmptyStateView(
                    title: "No archived sets yet",
                    systemImage: "music.note",
                    description: "Once DJMemory archives a recording, your last set will show up here.",
                    primaryTitle: "Choose Folder",
                    primaryAction: { model.selectedRoute = .protection }
                )
            }
        }
    }

    private var glanceTiles: some View {
        let stats = model.libraryStatistics
        return VStack(spacing: 8) {
            MetricTile(label: "Sets protected", value: "\(model.sessions.count)", meta: "\(stats.setsThisMonth) this month", tone: .ok)
            MetricTile(
                label: "Hours archived",
                value: String(format: "%.1fh", stats.totalDurationSeconds / 3600),
                meta: ByteCountFormatter.string(fromByteCount: stats.totalFileSize, countStyle: .file)
            )
            MetricTile(
                label: "Sources watched",
                value: "\(model.protectedAdapterCount)/\(model.probeResults.count)",
                tone: model.protectionState == .attentionNeeded ? .danger : .neutral
            )
            MetricTile(
                label: "Unmatched sets",
                value: "\(stats.unmatchedCount)",
                tone: stats.unmatchedCount > 0 ? .warn : .neutral
            )
        }
    }

    private var recentShelf: some View {
        Panel(title: "Recent sets", padding: 12) {
            if model.librarySummaries.isEmpty {
                Text("No recent sets yet.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.mutedForeground)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.librarySummaries.sorted(by: { $0.archive.detectedAt > $1.archive.detectedAt }).prefix(6)) { summary in
                            Button {
                                model.selectedRoute = .library
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Waveform(
                                        seed: summary.archive.originalFilename,
                                        barCount: 28,
                                        tint: DJToken.accent(forAppID: summary.archive.sourceAppID)
                                    )
                                    .frame(height: 36)
                                    Text(summary.context.eventName.isEmpty ? summary.archive.originalFilename : summary.context.eventName)
                                        .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                                        .foregroundStyle(DJToken.foreground)
                                        .lineLimit(1)
                                    Text([summary.context.venue, summary.context.city].filter { !$0.isEmpty }.joined(separator: ", "))
                                        .font(.system(size: DJToken.TypeSize.secondary))
                                        .foregroundStyle(DJToken.mutedForeground)
                                        .lineLimit(1)
                                    Rectangle().fill(DJToken.hairline).frame(height: 1)
                                    HStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: DJToken.Radius.swatch)
                                            .fill(DJToken.accent(forAppID: summary.archive.sourceAppID))
                                            .frame(width: 3, height: 10)
                                        Text(model.displayName(for: summary.archive.sourceAppID))
                                            .font(.system(size: DJToken.TypeSize.secondary))
                                            .foregroundStyle(DJToken.mutedForeground)
                                        Spacer()
                                        Text(formatDuration(summary.archive.durationSeconds))
                                            .font(.system(size: DJToken.TypeSize.secondary).monospacedDigit())
                                            .foregroundStyle(DJToken.mutedForeground)
                                    }
                                }
                                .padding(10)
                                .frame(width: 196, alignment: .leading)
                                .background(DJToken.elevated, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DJToken.Radius.control)
                                        .stroke(DJToken.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var topTracksAndActivity: some View {
        HStack(alignment: .top, spacing: 12) {
            Panel(title: "Your most played tracks", padding: 0) {
                if model.topTracks.isEmpty {
                    Text("Import a set history to see top tracks.")
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                        .padding(12)
                } else {
                    let maxPlays = max(model.topTracks.first?.playCount ?? 1, 1)
                    ForEach(Array(model.topTracks.enumerated()), id: \.offset) { index, track in
                        HStack(spacing: 10) {
                            Text(String(format: "%02d", index + 1))
                                .font(.system(size: DJToken.TypeSize.secondary, design: .monospaced))
                                .foregroundStyle(DJToken.mutedForeground)
                                .frame(width: 24, alignment: .leading)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(track.title.isEmpty ? "Unknown title" : track.title)
                                    .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                                Text(track.artist.isEmpty ? "Unknown artist" : track.artist)
                                    .font(.system(size: DJToken.TypeSize.secondary))
                                    .foregroundStyle(DJToken.mutedForeground)
                            }
                            Spacer()
                            Text(track.lastEventName)
                                .font(.system(size: DJToken.TypeSize.secondary))
                                .foregroundStyle(DJToken.mutedForeground)
                                .lineLimit(1)
                            ZStack(alignment: .leading) {
                                Rectangle().fill(DJToken.secondary).frame(width: 48, height: 1)
                                Rectangle().fill(DJToken.primary).frame(width: 48 * CGFloat(track.playCount) / CGFloat(maxPlays), height: 1)
                            }
                            Text("\(track.playCount)")
                                .font(.system(size: DJToken.TypeSize.secondary).monospacedDigit())
                                .frame(width: 24, alignment: .trailing)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        if index < model.topTracks.count - 1 {
                            Rectangle().fill(DJToken.hairline).frame(height: 1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Panel(
                title: "Latest activity",
                padding: 0,
                headerActions: {
                    Button("All activity") { model.selectedRoute = .activity }
                        .buttonStyle(DJGhostButtonStyle())
                }
            ) {
                ForEach(model.activityEvents.prefix(5)) { event in
                    HStack(spacing: 8) {
                        StatusDot(tone: event.kind == .error ? .danger : .neutral)
                        Text(event.message)
                            .font(.system(size: DJToken.TypeSize.body))
                            .lineLimit(1)
                        Spacer()
                        Text(event.createdAt, style: .time)
                            .font(.system(size: DJToken.TypeSize.secondary, design: .monospaced))
                            .foregroundStyle(DJToken.mutedForeground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(event.kind == .error ? DJToken.danger.opacity(0.06) : Color.clear)
                }
            }
            .frame(width: 320)
        }
    }

    private var venuesAndTags: some View {
        HStack(alignment: .top, spacing: 12) {
            Panel(title: "Where you play most", padding: 12) {
                if model.venueCounts.isEmpty {
                    Text("Add venues in set details to see them here.")
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(model.venueCounts, id: \.name) { venue in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(venue.name).font(.system(size: DJToken.TypeSize.body, weight: .medium))
                                Text(venue.city).font(.system(size: DJToken.TypeSize.secondary)).foregroundStyle(DJToken.mutedForeground)
                                Text("\(venue.setCount) sets").font(.system(size: DJToken.TypeSize.secondary).monospacedDigit()).foregroundStyle(DJToken.mutedForeground)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(DJToken.muted, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Panel(title: "Your tags", padding: 12) {
                Text("From set details you wrote.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.mutedForeground)
                if model.tagCounts.isEmpty {
                    Text("No tags yet.")
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                } else {
                    FlowTagWrap(tags: model.tagCounts)
                }
            }
            .frame(width: 320)
        }
    }

    private var djAppsSection: some View {
        Panel(title: "Your DJ apps", padding: 12) {
            VStack(spacing: 8) {
                ForEach(model.probeResults, id: \.software.id) { result in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: DJToken.Radius.swatch)
                            .fill(DJToken.accent(forAppID: result.software.id))
                            .frame(width: 3, height: 28)
                        Text(result.software.displayName)
                            .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                        SupportBadge(status: result.software.supportStatus)
                        Spacer()
                        let state = model.setupState(for: result)
                        StatusDot(tone: tone(for: state))
                        Text("\(state.displayName) · \(model.sessions.filter { $0.sourceAppID == result.software.id }.count) sets")
                            .font(.system(size: DJToken.TypeSize.secondary))
                            .foregroundStyle(DJToken.mutedForeground)
                        Button(actionLabel(for: result)) {
                            if model.isConfiguredRecordingsFolderUnreachable(appID: result.software.id) {
                                model.selectedRoute = .recovery(result.software.id)
                            } else {
                                model.selectedRoute = .app(result.software.id)
                            }
                        }
                        .buttonStyle(DJSecondaryButtonStyle())
                        .accessibilityIdentifier("home.app.\(result.software.id)")
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            if model.protectionState == .protected {
                Image(systemName: "checkmark.shield.fill").foregroundStyle(DJToken.ok)
            }
            Text("Audio files and full tracklists stay on this Mac. Nothing is uploaded.")
                .font(.system(size: DJToken.TypeSize.secondary))
                .foregroundStyle(DJToken.mutedForeground)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part: String
        switch hour {
        case 5..<12: part = "Good morning"
        case 12..<17: part = "Good afternoon"
        default: part = "Good evening"
        }
        if let name = model.profile.firstName {
            return "\(part), \(name)"
        }
        return part
    }

    private var metaLine: String {
        var parts: [String] = []
        if let handle = model.profile.handle, !handle.isEmpty {
            parts.append(handle)
        }
        if let city = model.profile.city, !city.isEmpty {
            parts.append(city)
        }
        if let residency = model.profile.residency, !residency.isEmpty {
            parts.append(residency)
        }
        if let since = model.profile.memberSince {
            parts.append("DJMemory since \(since.formatted(.dateTime.month().year()))")
        }
        return parts.isEmpty ? "Local-first set archive" : parts.joined(separator: " · ")
    }

    private var adaptiveSentence: String {
        let stats = model.libraryStatistics
        switch model.protectionState {
        case .protected:
            let weeks = stats.consecutiveWeeksRunning.map { " — you have \($0) weeks running with nothing lost" } ?? ""
            return "\(model.protectedAdapterCount) sources watched. Your last \(stats.setsThisMonth) sets this month were archived automatically\(weeks)."
        case .scanning:
            return "Checking \(model.protectedAdapterCount) watched folders for new recordings…"
        case .needsSetup:
            let remaining = model.probeResults.count - model.protectedAdapterCount
            return "\(model.protectedAdapterCount) of \(model.probeResults.count) sources watched. \(remaining) still need a folder before DJMemory can protect them."
        case .attentionNeeded:
            let app = model.unreachableRecordingAccesses().first.map { model.displayName(for: $0.appID) } ?? "a source"
            return "A saved folder is unavailable, so new sets from \(app) are not being archived right now. Everything already in your archive is safe."
        }
    }

    private var protectionTone: StatusTone {
        switch model.protectionState {
        case .protected: return .ok
        case .needsSetup: return .warn
        case .scanning: return .info
        case .attentionNeeded: return .danger
        }
    }

    private func actionLabel(for result: SoftwareProbeResult) -> String {
        if model.isConfiguredRecordingsFolderUnreachable(appID: result.software.id) { return "Fix" }
        if model.hasConfiguredRecordingsFolder(appID: result.software.id) { return "Manage" }
        return "Set up"
    }

    private func tone(for state: AppSetupState) -> StatusTone {
        switch state {
        case .watching, .archived: return .ok
        case .saving: return .info
        case .recordingDetected, .needsFolderAccess, .appNotFound: return .warn
        case .attentionNeeded, .error: return .danger
        }
    }

    private func subtitle(for summary: LibrarySessionSummary) -> String {
        let place = [summary.context.venue, summary.context.city].filter { !$0.isEmpty }.joined(separator: ", ")
        let archived = summary.archive.detectedAt.formatted(date: .abbreviated, time: .shortened)
        if place.isEmpty { return "Archived \(archived)" }
        return "\(place) · Archived \(archived)"
    }

    private func fact(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).microLabelStyle()
            Text(value).font(.system(size: DJToken.TypeSize.body, weight: .medium)).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatDuration(_ seconds: Double?) -> String {
        guard let seconds else { return "—" }
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}

private struct FlowTagWrap: View {
    let tags: [TagCount]

    var body: some View {
        FlexibleTagLayout(tags: tags)
    }
}

private struct FlexibleTagLayout: View {
    let tags: [TagCount]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(tags.prefix(12), id: \.display) { tag in
                Badge(title: "\(tag.display) · \(tag.count)", tone: .neutral)
            }
        }
    }
}

#Preview("Home empty") {
    ScrollView {
        HomeDashboardView()
            .padding()
    }
    .environmentObject(AppModel())
    .frame(width: 1000, height: 800)
    .background(DJToken.content)
}
