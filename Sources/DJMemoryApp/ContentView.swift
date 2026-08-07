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
            Section("DJMemory") {
                Label("Protection", systemImage: model.protectionSymbolName)
                    .tag("protection")
                Label("Library", systemImage: "music.note.list")
                    .tag("library")
                Label("Activity", systemImage: "clock.arrow.circlepath")
                    .tag("activity")
                Label("Settings", systemImage: "gearshape")
                    .tag("settings")
            }

            Section("DJ Apps") {
                ForEach(model.probeResults, id: \.software.id) { result in
                    Label(result.software.displayName, systemImage: iconName(for: result))
                        .tag(result.software.id)
                }
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

                if model.selectedAppID == "protection" {
                    ProtectionDashboardView()
                } else if model.selectedAppID == "library" {
                    SessionLibraryView()
                } else if model.selectedAppID == "activity" {
                    ActivityLogView()
                } else if model.selectedAppID == "settings" {
                    SettingsView()
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

private struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    private let intervalOptions = [30, 60, 120, 300]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 14) {
                Toggle(
                    "Automatic scanning",
                    isOn: Binding(
                        get: { model.settings.automaticScanningEnabled },
                        set: { model.updateAutomaticScanning(enabled: $0) }
                    )
                )
                .help("When on, DJMemory scans configured recording folders while the app is open.")

                Picker(
                    "Scan interval",
                    selection: Binding(
                        get: { model.settings.scanIntervalSeconds },
                        set: { model.updateScanInterval(seconds: $0) }
                    )
                ) {
                    ForEach(intervalOptions, id: \.self) { seconds in
                        Text(intervalLabel(seconds)).tag(seconds)
                    }
                }
                .disabled(!model.settings.automaticScanningEnabled)
                .pickerStyle(.segmented)
                .help("How often DJMemory checks configured recording folders while automatic scanning is on.")
            }
            .padding(14)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                Text("Archive Naming")
                    .font(.headline)

                TextField(
                    "Archive naming template",
                    text: Binding(
                        get: { model.settings.archiveNamingTemplate },
                        set: { model.updateArchiveNamingTemplate($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .help("Available tokens: {date}, {time}, {app}, {source}.")

                SettingsStatusRow(
                    title: "Example",
                    value: exampleArchiveName(),
                    symbol: "textformat"
                )
            }
            .padding(14)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                Text("Current State")
                    .font(.headline)

                SettingsStatusRow(
                    title: "Archive folder",
                    value: model.archiveRoot.path,
                    symbol: "archivebox"
                )

                SettingsStatusRow(
                    title: "Protected sources",
                    value: "\(model.protectedAdapterCount)",
                    symbol: "record.circle"
                )

                SettingsStatusRow(
                    title: "Imported tracklists",
                    value: "\(model.allImportedTracklists.count)",
                    symbol: "list.bullet.rectangle"
                )
            }
        }
    }

    private func intervalLabel(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s"
        }

        return "\(seconds / 60)m"
    }

    private func exampleArchiveName() -> String {
        let template = model.settings.archiveNamingTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? AppSettings.defaultArchiveNamingTemplate
            : model.settings.archiveNamingTemplate

        return template
            .replacingOccurrences(of: "{date}", with: "2026-08-06")
            .replacingOccurrences(of: "{time}", with: "2230")
            .replacingOccurrences(of: "{app}", with: "Serato DJ Pro")
            .replacingOccurrences(of: "{source}", with: "Club Recording")
            + ".wav"
    }
}

private struct SettingsStatusRow: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .frame(width: 18)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.callout.weight(.medium))
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(value)
        }
        .padding(12)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        .help("\(title): \(value)")
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

private struct ProtectionDashboardView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Protection")
                    .font(.title2.weight(.semibold))

                Spacer()

                Button {
                    model.scanNow()
                } label: {
                    Label(model.isScanning ? "Scanning" : "Scan Now", systemImage: "waveform.badge.magnifyingglass")
                }
                .disabled(model.isScanning)
                .controlSize(.large)
                .help("Scan every configured recording folder now.")
            }

            HStack(spacing: 12) {
                ProtectionMetric(
                    title: "Protected Sources",
                    value: "\(model.protectedAdapterCount)",
                    symbol: "record.circle",
                    tint: model.protectedAdapterCount > 0 ? .green : .secondary
                )
                ProtectionMetric(
                    title: "Archived Sets",
                    value: "\(model.sessions.count)",
                    symbol: "archivebox",
                    tint: .blue
                )
                ProtectionMetric(
                    title: "Imported Histories",
                    value: "\(model.allImportedTracklists.count)",
                    symbol: "list.bullet.rectangle",
                    tint: .purple
                )
            }

            if model.protectedAdapterCount == 0 {
                ContentUnavailableView(
                    "Choose a recording folder",
                    systemImage: "folder.badge.plus",
                    description: Text("Pick a DJ app below, then set the folder where it saves recordings.")
                )
                .frame(maxWidth: .infinity, minHeight: 180)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Sources")
                    .font(.headline)

                ForEach(model.probeResults, id: \.software.id) { result in
                    ProtectionSourceRow(
                        result: result,
                        state: model.setupState(for: result),
                        recordingFolders: model.recordingFolders(for: result.software.id),
                        historyFolders: model.historyFolders(for: result.software.id),
                        chooseRecording: {
                            model.selectedAppID = result.software.id
                            model.chooseFolder(appID: result.software.id, kind: .recordings)
                        },
                        openSetup: {
                            model.selectedAppID = result.software.id
                        }
                    )
                }
            }
        }
    }
}

private struct ProtectionMetric: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title2.weight(.semibold))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
        .padding(14)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
        .help("\(title): \(value)")
    }
}

private struct ProtectionSourceRow: View {
    let result: SoftwareProbeResult
    let state: String
    let recordingFolders: [URL]
    let historyFolders: [URL]
    let chooseRecording: () -> Void
    let openSetup: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sourceSymbol)
                .font(.title3)
                .foregroundStyle(sourceTint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.software.displayName)
                    .font(.callout.weight(.medium))
                Text(sourceDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(sourceDetail)
            }

            Spacer()

            Text(state)
                .font(.caption.weight(.medium))
                .foregroundStyle(sourceTint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sourceTint.opacity(0.12), in: Capsule())

            Button(action: openSetup) {
                Label("Setup", systemImage: "slider.horizontal.3")
            }
            .help("Open setup for \(result.software.displayName).")

            Button(action: chooseRecording) {
                Label("Folder", systemImage: "folder.badge.plus")
            }
            .help("Choose the recording folder for \(result.software.displayName).")
        }
        .padding(12)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }

    private var sourceSymbol: String {
        recordingFolders.isEmpty ? "circle" : "checkmark.circle.fill"
    }

    private var sourceTint: Color {
        if state == "Error" { return .orange }
        return recordingFolders.isEmpty ? .secondary : .green
    }

    private var sourceDetail: String {
        if let recordingFolder = recordingFolders.first {
            return "Recording: \(recordingFolder.path)"
        }

        if !result.installedApplicationURLs.isEmpty {
            return "App found. Recording folder still needs access."
        }

        if let historyFolder = historyFolders.first {
            return "History found: \(historyFolder.path)"
        }

        return "Manual setup available."
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

                FolderQuickActionsView(result: result)

                StatusGrid(
                    result: result,
                    setupState: model.setupState(for: result),
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
        case "traktor":
            return [
                "DJMemory checks ~/Music/Traktor/Recordings when it exists.",
                "Versioned Traktor History folders are detected under Native Instruments.",
                "Import Traktor .nml history playlists for tracklists."
            ]
        default:
            return [
                "Coming after Serato and rekordbox MVP support.",
                "Manual folder selection will be used before deeper integration."
            ]
        }
    }
}

private struct FolderQuickActionsView: View {
    @EnvironmentObject private var model: AppModel
    let result: SoftwareProbeResult

    var body: some View {
        HStack(spacing: 10) {
            Button {
                model.chooseFolder(appID: result.software.id, kind: .recordings)
            } label: {
                Label(recordingButtonTitle, systemImage: "folder.badge.plus")
            }
            .controlSize(.large)
            .help("Set the folder DJMemory scans for completed recordings.")

            Button {
                model.chooseFolder(appID: result.software.id, kind: .history)
            } label: {
                Label(historyButtonTitle, systemImage: "list.bullet.rectangle")
            }
            .controlSize(.large)
            .help("Set the folder where DJMemory can find history exports.")

            Spacer()
        }
    }

    private var recordingButtonTitle: String {
        model.recordingFolders(for: result.software.id).isEmpty ? "Set Recording Folder" : "Change Recording Folder"
    }

    private var historyButtonTitle: String {
        model.historyFolders(for: result.software.id).isEmpty ? "Set History Folder" : "Change History Folder"
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
                                Text("\(kindLabel(imported.kind)) | \(imported.tracks.count) track\(imported.tracks.count == 1 ? "" : "s") from \(imported.sourceURL.lastPathComponent)")
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

    private func kindLabel(_ kind: ImportedTracklistKind) -> String {
        switch kind {
        case .setHistory:
            return "Set history"
        case .collection:
            return "Collection"
        }
    }

    private func historyPrompt(for appID: String) -> String {
        switch appID {
        case "serato":
            return "Import a Serato History Export CSV or text file to preview tracklist parsing."
        case "rekordbox":
            return "Import a rekordbox XML or history export to test metadata compatibility."
        case "traktor":
            return "Import a Traktor NML history playlist to preview tracklist parsing."
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
                        HStack(spacing: 6) {
                            Image(systemName: folderIsReachable(folder) ? "checkmark.circle" : "exclamationmark.triangle")
                                .foregroundStyle(folderIsReachable(folder) ? .green : .orange)
                            Text(folder.path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(folder.path)
                        }
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

        let inaccessible = folders.filter { !folderIsReachable($0) }
        if !inaccessible.isEmpty {
            return "Some saved folders are not reachable. Choose the folder again to recover access.\n\(inaccessible.map(\.path).joined(separator: "\n"))"
        }

        return folders.map(\.path).joined(separator: "\n")
    }

    private func folderIsReachable(_ folder: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: folder.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}

private struct StatusGrid: View {
    let result: SoftwareProbeResult
    let setupState: String
    let recordingFolders: [URL]
    let historyFolders: [URL]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
            GridRow {
                StatusTile(title: "State", value: setupState, symbol: stateSymbol)
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

    private var stateSymbol: String {
        switch setupState {
        case "Archived":
            return "checkmark.seal"
        case "Error":
            return "exclamationmark.triangle"
        case "Needs folder access":
            return "folder.badge.questionmark"
        case "App not found":
            return "questionmark.app"
        case "Scanning":
            return "waveform.badge.magnifyingglass"
        default:
            return "record.circle"
        }
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
    @State private var selectedSessionID: LibrarySessionSummary.ID?
    @State private var selectedTracklistID: ImportedTracklist.ID?
    @State private var trackSearch = ""

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
                Table(model.librarySummaries, selection: $selectedSessionID) {
                    TableColumn("Recording") { summary in
                        Text(summary.archive.originalFilename)
                            .help(summary.archive.originalFilename)
                    }
                    TableColumn("App") { summary in
                        Text(model.displayName(for: summary.archive.sourceAppID))
                            .help(summary.archive.sourceAppID)
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

                if let summary = selectedSession {
                    SetDetailView(
                        summary: summary,
                        appName: model.displayName(for: summary.archive.sourceAppID),
                        candidateTracklists: model.allImportedTracklists.filter {
                            $0.appID == summary.archive.sourceAppID && $0.kind.isMatchableToRecording
                        },
                        activityEvents: model.activityEvents.filter {
                            ($0.detail ?? "").contains(summary.archive.originalFilename)
                                || ($0.detail ?? "").contains(summary.archive.archivePath)
                                || ($0.detail ?? "").contains(summary.archive.sourcePath)
                        },
                        saveContext: model.saveSetContext,
                        attachTracklist: { model.attachTracklist(sessionID: summary.id, tracklistID: $0) },
                        revealArchive: { model.revealInFinder(URL(fileURLWithPath: summary.archive.archivePath)) },
                        revealSource: { model.revealInFinder(URL(fileURLWithPath: summary.archive.sourcePath)) }
                    )
                } else {
                    Text("Select an archived set to review details, notes, and tracklist matching.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72)
                }
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
                Table(model.allImportedTracklists, selection: $selectedTracklistID) {
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
                        Text(model.displayName(for: tracklist.appID))
                            .help(tracklist.appID)
                    }
                    TableColumn("Tracks") { tracklist in
                        Text("\(tracklist.tracks.count)")
                    }
                    TableColumn("Kind") { tracklist in
                        Text(kindLabel(tracklist.kind))
                            .help(kindHelp(tracklist.kind))
                    }
                    TableColumn("Preview") { tracklist in
                        Text(previewText(for: tracklist))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .help(previewText(for: tracklist))
                    }
                }
                .frame(minHeight: 260)

                if let tracklist = selectedTracklist {
                    TracklistDetailView(
                        tracklist: tracklist,
                        appName: model.displayName(for: tracklist.appID),
                        searchText: $trackSearch,
                        revealInFinder: { model.revealInFinder(tracklist.sourceURL) }
                    )
                } else {
                    Text("Select an imported tracklist to browse its tracks.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72)
                }
            }
        }
        .onChange(of: selectedTracklistID) {
            trackSearch = ""
        }
        .onChange(of: model.librarySummaries.map(\.id)) {
            if let selectedSessionID,
               !model.librarySummaries.contains(where: { $0.id == selectedSessionID }) {
                self.selectedSessionID = nil
            }
        }
        .onChange(of: model.allImportedTracklists.map(\.id)) {
            if let selectedTracklistID,
               !model.allImportedTracklists.contains(where: { $0.id == selectedTracklistID }) {
                self.selectedTracklistID = nil
            }
        }
    }

    private var selectedTracklist: ImportedTracklist? {
        guard let selectedTracklistID else { return nil }
        return model.allImportedTracklists.first { $0.id == selectedTracklistID }
    }

    private var selectedSession: LibrarySessionSummary? {
        guard let selectedSessionID else { return nil }
        return model.librarySummaries.first { $0.id == selectedSessionID }
    }

    private func previewText(for tracklist: ImportedTracklist) -> String {
        tracklist.tracks.prefix(3).map(\.title).joined(separator: " / ")
    }

    private func kindLabel(_ kind: ImportedTracklistKind) -> String {
        switch kind {
        case .setHistory:
            return "Set history"
        case .collection:
            return "Collection"
        }
    }

    private func kindHelp(_ kind: ImportedTracklistKind) -> String {
        switch kind {
        case .setHistory:
            return "Can be matched to archived recordings from the same DJ app."
        case .collection:
            return "Browsable library import. It will not be auto-matched to one archived recording."
        }
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

private struct TracklistDetailView: View {
    let tracklist: ImportedTracklist
    let appName: String
    @Binding var searchText: String
    let revealInFinder: () -> Void

    private var filteredTracks: [TrackPlay] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return tracklist.tracks }

        return tracklist.tracks.filter { track in
            track.title.localizedCaseInsensitiveContains(query)
                || track.artist.localizedCaseInsensitiveContains(query)
                || (track.startTime?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(tracklist.sourceURL.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .help(tracklist.sourceURL.path)
                    Text("\(appName) | \(kindLabel(tracklist.kind)) | \(tracklist.tracks.count) tracks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                TextField("Search tracks", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)
                    .help("Filter this tracklist by title, artist, or play time.")

                Button(action: revealInFinder) {
                    Label("Reveal", systemImage: "arrow.up.forward.app")
                }
                .help("Reveal the source tracklist in Finder.")
            }

            Table(filteredTracks) {
                TableColumn("#") { track in
                    Text(trackNumber(for: track))
                        .foregroundStyle(.secondary)
                }
                .width(min: 34, ideal: 42, max: 52)

                TableColumn("Title") { track in
                    Text(track.title.isEmpty ? "Unknown title" : track.title)
                        .help(track.title)
                }

                TableColumn("Artist") { track in
                    Text(track.artist.isEmpty ? "Unknown artist" : track.artist)
                        .foregroundStyle(track.artist.isEmpty ? .secondary : .primary)
                        .help(track.artist.isEmpty ? "No artist was included in the imported file." : track.artist)
                }

                TableColumn("Played") { track in
                    Text(track.startTime ?? "Unknown")
                        .foregroundStyle(track.startTime == nil ? .secondary : .primary)
                }
                .width(min: 80, ideal: 110, max: 150)
            }
            .frame(minHeight: 300)
            .overlay {
                if filteredTracks.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .padding(.top, 4)
    }

    private func trackNumber(for track: TrackPlay) -> String {
        guard let index = tracklist.tracks.firstIndex(where: { $0.id == track.id }) else { return "-" }
        return "\(index + 1)"
    }

    private func kindLabel(_ kind: ImportedTracklistKind) -> String {
        switch kind {
        case .setHistory:
            return "Set history"
        case .collection:
            return "Collection"
        }
    }
}

private struct SetDetailView: View {
    let summary: LibrarySessionSummary
    let appName: String
    let candidateTracklists: [ImportedTracklist]
    let activityEvents: [ActivityEvent]
    let saveContext: (SetContext) -> Void
    let attachTracklist: (UUID?) -> Void
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
        revealArchive: @escaping () -> Void,
        revealSource: @escaping () -> Void
    ) {
        self.summary = summary
        self.appName = appName
        self.candidateTracklists = candidateTracklists
        self.activityEvents = activityEvents
        self.saveContext = saveContext
        self.attachTracklist = attachTracklist
        self.revealArchive = revealArchive
        self.revealSource = revealSource
        _draftContext = State(initialValue: summary.context)
        _selectedTracklistID = State(initialValue: summary.matchedTracklist?.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.archive.originalFilename)
                        .font(.headline)
                    Text("\(appName) | \(formatBytes(summary.archive.fileSize)) | \(formatDuration(summary.archive.durationSeconds))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: revealSource) {
                    Label("Source", systemImage: "arrow.up.forward.app")
                }
                .help(summary.archive.sourcePath)

                Button(action: revealArchive) {
                    Label("Archive", systemImage: "folder")
                }
                .help(summary.archive.archivePath)
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
                    .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
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

                Button {
                    selectedTracklistID = nil
                    attachTracklist(nil)
                } label: {
                    Label("Detach", systemImage: "link.badge.minus")
                }
                .disabled(summary.matchedTracklist == nil && summary.context.manualTracklistID == nil)
                .help("Remove the manual tracklist attachment for this set.")

                Spacer()

                Button {
                    draftContext.manualTracklistID = selectedTracklistID
                    saveContext(draftContext)
                } label: {
                    Label("Save Details", systemImage: "square.and.arrow.down")
                }
                .keyboardShortcut("s", modifiers: [.command])
                .help("Save event, venue, city, tags, notes, and manual tracklist selection.")
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
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
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
