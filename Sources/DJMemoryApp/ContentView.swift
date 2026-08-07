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
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
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
                } else {
                    AdapterDetailView()
                }
            }
            .padding(28)
        }
        .background(Color(nsColor: .windowBackgroundColor))
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
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Archive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(model.archiveRoot.path)
                    .font(.callout.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(model.archiveRoot.path)
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

                            if let errorDescription = result.errorDescription {
                                Text(errorDescription)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(result.archivedSessions.count) new recording\(result.archivedSessions.count == 1 ? "" : "s") archived")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
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
                clearAction: { model.clearFolder(appID: result.software.id, kind: .recordings) }
            )

            FolderRow(
                title: "History",
                folders: model.historyFolders(for: result.software.id),
                chooseAction: { model.chooseFolder(appID: result.software.id, kind: .history) },
                clearAction: { model.clearFolder(appID: result.software.id, kind: .history) }
            )
        }
    }
}

private struct FolderRow: View {
    let title: String
    let folders: [URL]
    let chooseAction: () -> Void
    let clearAction: () -> Void

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

            Button {
                clearAction()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
            }
            .disabled(folders.isEmpty)
        }
        .padding(14)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
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
    }
}

private struct SessionLibraryView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Archived Sets")
                .font(.title2.weight(.semibold))

            if model.sessions.isEmpty {
                ContentUnavailableView(
                    "No archived sets yet",
                    systemImage: "music.note",
                    description: Text("Archived recordings will appear here after DJMemory saves them.")
                )
                .frame(maxWidth: .infinity, minHeight: 280)
            } else {
                Table(model.sessions, selection: .constant(nil)) {
                    TableColumn("Original") { metadata in
                        Text(metadata.originalFilename)
                    }
                    TableColumn("Source") { metadata in
                        Text(metadata.sourceAppID)
                    }
                    TableColumn("Archived") { metadata in
                        Text(metadata.archivePath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .frame(minHeight: 340)
            }
        }
    }
}
