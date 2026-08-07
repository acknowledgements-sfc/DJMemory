import SwiftUI
import DJMemoryCore

struct SetDetailView: View {
    let summary: LibrarySessionSummary
    let appName: String
    let candidateTracklists: [ImportedTracklist]
    let activityEvents: [ActivityEvent]
    let saveContext: (SetContext) -> Void
    let attachTracklist: (UUID?) -> Void
    let importTracklist: () -> Void
    let exportPublishPack: () -> Void
    let revealArchive: () -> Void
    let revealSource: () -> Void

    @State private var draftContext: SetContext
    @State private var selectedTracklistID: UUID?

    init(
        summary: LibrarySessionSummary,
        appName: String,
        candidateTracklists: [ImportedTracklist],
        activityEvents: [ActivityEvent],
        saveContext: @escaping (SetContext) -> Void,
        attachTracklist: @escaping (UUID?) -> Void,
        importTracklist: @escaping () -> Void = {},
        exportPublishPack: @escaping () -> Void = {},
        revealArchive: @escaping () -> Void,
        revealSource: @escaping () -> Void
    ) {
        self.summary = summary
        self.appName = appName
        self.candidateTracklists = candidateTracklists
        self.activityEvents = activityEvents
        self.saveContext = saveContext
        self.attachTracklist = attachTracklist
        self.importTracklist = importTracklist
        self.exportPublishPack = exportPublishPack
        self.revealArchive = revealArchive
        self.revealSource = revealSource
        _draftContext = State(initialValue: summary.context)
        _selectedTracklistID = State(initialValue: summary.matchedTracklist?.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Waveform(
                seed: summary.archive.originalFilename,
                barCount: 64,
                tint: DJToken.accent(forAppID: summary.archive.sourceAppID)
            )
            .frame(height: 40)
            .padding(8)
            .background(DJToken.muted, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.archive.originalFilename)
                        .font(.headline)
                    Text("\(appName) | \(formatBytes(summary.archive.fileSize)) | \(formatDuration(summary.archive.durationSeconds))")
                        .font(.caption)
                        .foregroundStyle(DJToken.mutedForeground)
                }

                Spacer()

                Button(action: revealSource) {
                    Label("Source", systemImage: "arrow.up.forward.app")
                }
                .help(summary.archive.sourcePath)
                .accessibilityIdentifier("setDetail.\(summary.id).revealSource")

                Button(action: revealArchive) {
                    Label("Archive", systemImage: "folder")
                }
                .help(summary.archive.archivePath)
                .accessibilityIdentifier("setDetail.\(summary.id).revealArchive")
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    detailField("Event", text: $draftContext.eventName)
                    detailField("Venue", text: $draftContext.venue)
                }

                GridRow {
                    detailField("City", text: $draftContext.city)
                    detailField("Tags", text: $draftContext.tags)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.callout.weight(.medium))
                TextEditor(text: $draftContext.notes)
                    .font(.callout)
                    .frame(minHeight: 72)
                    .scrollContentBackground(.hidden)
                    .background(DJToken.muted, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
                    .overlay(
                        RoundedRectangle(cornerRadius: DJToken.Radius.control)
                            .stroke(DJToken.border, lineWidth: 1)
                    )
                    .help("Private local notes for this archived set.")
            }

            HStack {
                Picker("Tracklist", selection: $selectedTracklistID) {
                    Text(summary.matchedTracklist == nil ? "Automatic / None" : "Automatic match").tag(Optional<UUID>.none)
                    ForEach(candidateTracklists) { tracklist in
                        Text("\(tracklist.sourceURL.lastPathComponent) (\(tracklist.tracks.count))")
                            .tag(Optional(tracklist.id))
                    }
                }
                .help("Manually attach a set-history import when the automatic match is missing or wrong.")

                Button {
                    attachTracklist(selectedTracklistID)
                } label: {
                    Label("Apply Match", systemImage: "link")
                }
                .disabled(selectedTracklistID == summary.context.manualTracklistID)
                .help("Save this tracklist match for the selected archived set.")
                .accessibilityIdentifier("setDetail.\(summary.id).applyMatch")

                Button {
                    selectedTracklistID = nil
                    attachTracklist(nil)
                } label: {
                    Label("Detach", systemImage: "link.badge.minus")
                }
                .disabled(summary.matchedTracklist == nil && summary.context.manualTracklistID == nil)
                .help("Remove the manual tracklist attachment for this set.")
                .accessibilityIdentifier("setDetail.\(summary.id).detachMatch")

                Button(action: importTracklist) {
                    Label("Import Tracklist", systemImage: "square.and.arrow.down")
                }
                .help("Import a history or USB export, then attach it to this set.")
                .accessibilityIdentifier("setDetail.\(summary.id).importTracklist")

                Button(action: exportPublishPack) {
                    Label("Export Pack", systemImage: "square.and.arrow.up")
                }
                .help("Export a local publish pack. Nothing is uploaded.")
                .accessibilityIdentifier("setDetail.\(summary.id).exportPack")

                Spacer()

                Button {
                    draftContext.manualTracklistID = selectedTracklistID
                    saveContext(draftContext)
                } label: {
                    Label("Save Details", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: [.command])
                .help("Save event, venue, city, tags, notes, and manual tracklist selection.")
                .accessibilityIdentifier("setDetail.\(summary.id).saveDetails")
            }

            if let tracklist = summary.matchedTracklist {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Matched Tracklist")
                        .font(.callout.weight(.medium))

                    ForEach(tracklist.tracks.prefix(6)) { track in
                        HStack {
                            Text(track.artist.isEmpty ? "Unknown Artist" : track.artist)
                                .frame(width: 180, alignment: .leading)
                                .foregroundStyle(track.artist.isEmpty ? .secondary : .primary)
                            Text(track.title.isEmpty ? "Unknown title" : track.title)
                            Spacer()
                            Text(track.startTime ?? "")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .font(.callout)
                    }
                }
            }

            if !activityEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Related Activity")
                        .font(.callout.weight(.medium))

                    ForEach(activityEvents.prefix(5)) { event in
                        Text("\(event.createdAt.formatted(date: .abbreviated, time: .shortened)) - \(event.message)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help([event.message, event.detail].compactMap { $0 }.joined(separator: "\n"))
                    }
                }
            }
        }
        .padding(14)
        .background(DJToken.card, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: DJToken.Radius.control)
                .stroke(DJToken.border, lineWidth: 1)
        )
        .onChange(of: summary.id) {
            draftContext = summary.context
            selectedTracklistID = summary.matchedTracklist?.id
        }
    }

    private func detailField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.callout.weight(.medium))
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .help(title)
        }
    }

    private func formatDuration(_ seconds: Double?) -> String {
        guard let seconds else { return "Unknown duration" }
        let totalSeconds = Int(seconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
