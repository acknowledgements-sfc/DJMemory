import SwiftUI
import DJMemoryCore

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            DashboardView()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.scanNow()
                } label: {
                    Label(model.isScanning ? "Scanning" : "Scan Now", systemImage: "waveform.badge.magnifyingglass")
                }
                .disabled(model.isScanning)
                .help("Scan configured recording folders for new completed audio files.")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh app detection, folder access, imports, archive metadata, and activity.")
            }
        }
    }
}

private struct Sidebar: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        List(selection: $model.selectedAppID) {
            Section("Setup") {
                ForEach(model.probeResults, id: \.software.id) { result in
                    Label(result.software.displayName, systemImage: iconName(for: result))
                        .tag(result.software.id)
                }
            }

            Section("Library") {
                Label("Archived Sets", systemImage: "music.note.list")
                    .tag("library")
                Label("Activity", systemImage: "clock.arrow.circlepath")
                    .tag("activity")
            }
        }
        .navigationTitle("DJMemory")
    }

    private func iconName(for result: SoftwareProbeResult) -> String {
        switch result.status {
        case "installed", "folders-found":
            return "checkmark.circle"
        default:
            return "circle"
        }
    }
}

private struct DashboardView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView()

                if model.selectedAppID == "library" {
                    SessionLibraryView()
                } else if model.selectedAppID == "activity" {
                    ActivityLogView()
                } else {
                    AdapterDetailView()
                }
            }
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ActivityLogView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Activity")
                    .font(.title2.weight(.semibold))

                Spacer()

                Button {
                    model.exportDiagnostics()
                } label: {
                    Label("Export Diagnostics", systemImage: "doc.badge.gearshape")
                }
                .help("Save a JSON diagnostics report for troubleshooting DJMemory setup and library state.")

                Button {
                    model.clearActivity()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(model.activityEvents.isEmpty)
                .help("Clear the local activity log.")
            }

            if model.activityEvents.isEmpty {
                ContentUnavailableView(
                    "No activity yet",
                    systemImage: "clock",
                    description: Text("Scans, imports, archive events, and errors will appear here.")
                )
                .frame(maxWidth: .infinity, minHeight: 280)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.activityEvents) { event in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: symbolName(for: event.kind))
                                .foregroundStyle(color(for: event.kind))
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.message)
                                    .font(.callout.weight(.medium))

                                if let detail = event.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .truncationMode(.middle)
                                }
                            }

                            Spacer()

                            Text(event.createdAt, style: .time)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                        .help(activityHelp(for: event))
                    }
                }
            }
        }
    }

    private func symbolName(for kind: ActivityEventKind) -> String {
        switch kind {
        case .archive:
            return "tray.and.arrow.down"
        case .importTracklist:
            return "list.bullet.rectangle"
        case .scan:
            return "waveform.badge.magnifyingglass"
        case .error:
            return "exclamationmark.triangle"
        }
    }

    private func color(for kind: ActivityEventKind) -> Color {
        switch kind {
        case .archive:
            return .green
        case .importTracklist:
            return .blue
        case .scan:
            return .secondary
        case .error:
            return .orange
        }
    }

    private func activityHelp(for event: ActivityEvent) -> String {
        [event.message, event.detail].compactMap { $0 }.joined(separator: "\n")
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: model.protectionSymbolName)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(model.protectedAdapterCount > 0 ? .green : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(model.headlineStatus)
                    .font(.system(size: 28, weight: .semibold))
                Text(model.statusMessage)
                    .foregroundStyle(.secondary)
                    .help(model.statusMessage)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Archive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(model.archiveRoot.path)
                        .font(.callout.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(model.archiveRoot.path)

                    Button {
                        model.openArchiveFolder()
                    } label: {
                        Label("Open", systemImage: "folder")
                    }
                    .help("Open the DJMemory archive folder in Finder.")
                }
            }
        }
    }
}

private struct AdapterDetailView: View {
    @EnvironmentObject private var model: AppModel

    var selectedResult: SoftwareProbeResult? {
        model.probeResults.first { $0.software.id == model.selectedAppID } ?? model.probeResults.first
    }

    var body: some View {
        if let result = selectedResult {
            VStack(alignment: .leading, spacing: 18) {
                Text(result.software.displayName)
                    .font(.title2.weight(.semibold))

                StatusGrid(
                    result: result,
                    recordingFolders: model.recordingFolders(for: result.software.id),
                    historyFolders: model.historyFolders(for: result.software.id)
                )

                FolderSetupView(result: result)

                ScanResultsView(results: model.scanResults(for: result.software.id))

                HistoryImportView(result: result)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Setup")
                        .font(.headline)

                    ForEach(setupSteps(for: result), id: \.self) { step in
                        Label(step, systemImage: "checklist")
                            .foregroundStyle(.primary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Integration")
                        .font(.headline)
                    Text(result.software.notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func setupSteps(for result: SoftwareProbeResult) -> [String] {
        switch result.software.id {
        case "serato":
            return [
                "Grant access to ~/Music/_Serato_ when prompted.",
                "DJMemory watches the Recording folder.",
                "History Export files will be used for tracklists."
            ]
        case "rekordbox":
            return [
                "Choose the folder where rekordbox saves recordings.",
                "Import rekordbox XML or history exports when available.",
                "DJMemory preserves completed recordings in ~/Music/DJMemory."
            ]
        default:
            return [
                "Coming after Serato and rekordbox MVP support.",
                "Manual folder selection will be used before deeper integration."
            ]
        }
    }
}

private struct HistoryImportView: View {
    @EnvironmentObject private var model: AppModel
    let result: SoftwareProbeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Track History")
                    .font(.headline)

                Spacer()

                Button {
                    model.importHistory(appID: result.software.id)
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .help("Import a history or tracklist export for \(result.software.displayName).")
            }

            let imports = model.importedTracklists(for: result.software.id)

            if !imports.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(imports) { imported in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(imported.tracks.count) track\(imported.tracks.count == 1 ? "" : "s") from \(imported.sourceURL.lastPathComponent)")
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Button {
                                    model.deleteImportedTracklist(id: imported.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .help("Delete this imported tracklist from DJMemory. The original file is not changed.")
                            }

                            ForEach(imported.tracks.prefix(5)) { track in
                                HStack {
                                    Text(track.artist.isEmpty ? "Unknown Artist" : track.artist)
                                        .frame(width: 180, alignment: .leading)
                                    Text(track.title)
                                    Spacer()
                                    if let startTime = track.startTime {
                                        Text(startTime)
                                            .font(.caption.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.callout)
                            }
                        }
                        .padding(14)
                        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                        .help(imported.sourceURL.path)
                    }
                }
            } else {
                Text(historyPrompt(for: result.software.id))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func historyPrompt(for appID: String) -> String {
        switch appID {
        case "serato":
            return "Import a Serato History Export CSV or text file to preview tracklist parsing."
        case "rekordbox":
            return "Import a rekordbox XML or history export to test metadata compatibility."
        default:
            return "History import is planned after Serato and rekordbox support."
        }
    }
}

private struct ScanResultsView: View {
    let results: [FolderScanResult]

    var body: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Latest Scan")
                    .font(.headline)

                ForEach(results, id: \.folderURL) { result in
                    HStack(spacing: 10) {
                        Image(systemName: result.errorDescription == nil ? "checkmark.circle" : "exclamationmark.triangle")
                            .foregroundStyle(result.errorDescription == nil ? .green : .orange)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(result.folderURL.path)
                                .font(.caption.monospaced())
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(result.folderURL.path)

                            if let errorDescription = result.errorDescription {
                                Text(errorDescription)
                                    .foregroundStyle(.secondary)
                                    .help(errorDescription)
                            } else {
                                Text("\(result.archivedSessions.count) new recording\(result.archivedSessions.count == 1 ? "" : "s") archived")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                    .help(scanResultHelp(for: result))
                }
            }
        }
    }

    private func scanResultHelp(for result: FolderScanResult) -> String {
        if let errorDescription = result.errorDescription {
            return "\(result.folderURL.path)\n\(errorDescription)"
        }

        return "\(result.folderURL.path)\n\(result.archivedSessions.count) new recording\(result.archivedSessions.count == 1 ? "" : "s") archived"
    }
}

private struct FolderSetupView: View {
    @EnvironmentObject private var model: AppModel
    let result: SoftwareProbeResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folders")
                .font(.headline)

            FolderRow(
                title: "Recordings",
                folders: model.recordingFolders(for: result.software.id),
                chooseAction: { model.chooseFolder(appID: result.software.id, kind: .recordings) },
                clearAction: { model.clearFolder(appID: result.software.id, kind: .recordings) },
                revealAction: { model.revealInFinder($0) }
            )

            FolderRow(
                title: "History",
                folders: model.historyFolders(for: result.software.id),
                chooseAction: { model.chooseFolder(appID: result.software.id, kind: .history) },
                clearAction: { model.clearFolder(appID: result.software.id, kind: .history) },
                revealAction: { model.revealInFinder($0) }
            )
        }
    }
}

private struct FolderRow: View {
    let title: String
    let folders: [URL]
    let chooseAction: () -> Void
    let clearAction: () -> Void
    let revealAction: (URL) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.medium))

                if folders.isEmpty {
                    Text("No folder selected")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(folders, id: \.self) { folder in
                        Text(folder.path)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(folder.path)
                    }
                }
            }

            Spacer()

            Button {
                chooseAction()
            } label: {
                Label("Choose", systemImage: "folder.badge.plus")
            }
            .help("Choose the \(title.lowercased()) folder DJMemory can access.")

            Button {
                if let folder = folders.first {
                    revealAction(folder)
                }
            } label: {
                Label("Reveal", systemImage: "arrow.up.forward.app")
            }
            .disabled(folders.isEmpty)
            .help("Reveal the selected \(title.lowercased()) folder in Finder.")

            Button {
                clearAction()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
            }
            .disabled(folders.isEmpty)
            .help("Forget the selected \(title.lowercased()) folder. Files are not deleted.")
        }
        .padding(14)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        .help(folderRowHelp)
    }

    private var folderRowHelp: String {
        if folders.isEmpty {
            return "No \(title.lowercased()) folder is selected yet."
        }

        return folders.map(\.path).joined(separator: "\n")
    }
}

private struct StatusGrid: View {
    let result: SoftwareProbeResult
    let recordingFolders: [URL]
    let historyFolders: [URL]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                StatusTile(title: "App", value: appStatus, symbol: "macwindow")
                StatusTile(title: "Recordings", value: recordingStatus, symbol: "waveform")
                StatusTile(title: "History", value: historyStatus, symbol: "list.bullet.rectangle")
            }
        }
    }

    private var appStatus: String {
        result.installedApplicationURLs.isEmpty ? "Not found" : "Found"
    }

    private var recordingStatus: String {
        recordingFolders.isEmpty ? "Needs folder" : "Ready"
    }

    private var historyStatus: String {
        historyFolders.isEmpty ? "Optional" : "Found"
    }
}

private struct StatusTile: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.medium))
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .help("\(title): \(value)")
    }
}

private struct SessionLibraryView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Archived Sets")
                .font(.title2.weight(.semibold))

            if model.librarySummaries.isEmpty {
                ContentUnavailableView(
                    "No archived sets yet",
                    systemImage: "music.note",
                    description: Text("Choose a recordings folder and run Scan Now to archive completed audio files.")
                )
                .frame(maxWidth: .infinity, minHeight: 280)
            } else {
                Table(model.librarySummaries, selection: .constant(nil)) {
                    TableColumn("Recording") { summary in
                        Text(summary.archive.originalFilename)
                            .help(summary.archive.originalFilename)
                    }
                    TableColumn("App") { summary in
                        Text(summary.archive.sourceAppID)
                    }
                    TableColumn("Tracks") { summary in
                        Text(summary.trackCount == 0 ? "No tracklist" : "\(summary.trackCount)")
                    }
                    TableColumn("Duration") { summary in
                        Text(formatDuration(summary.archive.durationSeconds))
                    }
                    TableColumn("Size") { summary in
                        Text(formatBytes(summary.archive.fileSize))
                    }
                    TableColumn("Tracklist") { summary in
                        Text(summary.matchedTracklist?.sourceURL.lastPathComponent ?? "None")
                            .help(summary.matchedTracklist?.sourceURL.path ?? "No tracklist matched")
                    }
                    TableColumn("Archived") { summary in
                        HStack {
                            Text(summary.archive.archivePath)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(summary.archive.archivePath)

                            Button {
                                model.revealInFinder(URL(fileURLWithPath: summary.archive.archivePath))
                            } label: {
                                Label("Reveal", systemImage: "arrow.up.forward.app")
                            }
                            .help("Reveal this archived recording in Finder.")
                        }
                    }
                }
                .frame(minHeight: 340)
            }

            Divider()
                .padding(.vertical, 8)

            Text("Imported Tracklists")
                .font(.title2.weight(.semibold))

            if model.allImportedTracklists.isEmpty {
                ContentUnavailableView(
                    "No imported tracklists yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Import Serato CSV/TXT or rekordbox XML files from a setup card.")
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                Table(model.allImportedTracklists, selection: .constant(nil)) {
                    TableColumn("File") { tracklist in
                        HStack {
                            Text(tracklist.sourceURL.lastPathComponent)
                                .help(tracklist.sourceURL.path)

                            Button {
                                model.revealInFinder(tracklist.sourceURL)
                            } label: {
                                Label("Reveal", systemImage: "arrow.up.forward.app")
                            }
                            .help("Reveal this imported tracklist in Finder.")
                        }
                    }
                    TableColumn("App") { tracklist in
                        Text(tracklist.appID)
                    }
                    TableColumn("Tracks") { tracklist in
                        Text("\(tracklist.tracks.count)")
                    }
                    TableColumn("Preview") { tracklist in
                        Text(previewText(for: tracklist))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .help(previewText(for: tracklist))
                    }
                }
                .frame(minHeight: 260)
            }
        }
    }

    private func previewText(for tracklist: ImportedTracklist) -> String {
        tracklist.tracks.prefix(3).map(\.title).joined(separator: " / ")
    }

    private func formatDuration(_ seconds: Double?) -> String {
        guard let seconds else { return "Unknown" }
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
