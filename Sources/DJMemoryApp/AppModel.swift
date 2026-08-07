import AppKit
import Foundation
import DJMemoryCore
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var probeResults: [SoftwareProbeResult] = []
    @Published private(set) var sessions: [ArchiveMetadata] = []
    @Published private(set) var folderAccesses: [FolderAccess] = []
    @Published private(set) var lastScanResults: [FolderScanResult] = []
    @Published private(set) var importedTracklists: [String: [ImportedTracklist]] = [:]
    @Published private(set) var librarySummaries: [LibrarySessionSummary] = []
    @Published private(set) var activityEvents: [ActivityEvent] = []
    @Published private(set) var settings = AppSettings.default
    @Published private(set) var isScanning = false
    @Published var selectedAppID: String?
    @Published var statusMessage = "Checking protection status"

    let archiveRoot = ArchiveService.defaultArchiveRoot()
    private let probe = SoftwareProbe()
    private let library = SessionLibrary()
    private let folderAccessStore = FolderAccessStore()
    private let importedTracklistStore = ImportedTracklistStore()
    private let activityLogStore = ActivityLogStore()
    private let appSettingsStore = AppSettingsStore()
    private let notificationService = LocalNotificationService()
    private var scanTask: Task<Void, Never>?

    init() {
        notificationService.requestAuthorization()
        refresh()
        startBackgroundScanning()
    }

    deinit {
        scanTask?.cancel()
    }

    var protectedAdapterCount: Int {
        probeResults.filter { result in
            !recordingFolders(for: result.software.id).isEmpty
        }.count
    }

    var protectionSymbolName: String {
        protectedAdapterCount > 0 ? "record.circle.fill" : "record.circle"
    }

    var headlineStatus: String {
        protectedAdapterCount > 0 ? "Protected" : "Needs setup"
    }

    func refresh() {
        probeResults = probe.probeAll()
        sessions = (try? library.archivedMetadata()) ?? []
        folderAccesses = (try? folderAccessStore.all()) ?? []
        importedTracklists = Dictionary(
            grouping: (try? importedTracklistStore.all()) ?? [],
            by: \.appID
        ).mapValues { $0.sorted { $0.importedAt > $1.importedAt } }
        librarySummaries = LibrarySessionMatcher().summaries(
            archives: sessions,
            importedTracklists: importedTracklists.values.flatMap { $0 }
        )
        activityEvents = (try? activityLogStore.all()) ?? []
        settings = (try? appSettingsStore.load()) ?? .default

        if protectedAdapterCount > 0 {
            statusMessage = "\(protectedAdapterCount) source\(protectedAdapterCount == 1 ? "" : "s") ready"
        } else {
            statusMessage = "Choose recording folders to start protecting sets"
        }

        selectedAppID = selectedAppID ?? probeResults.first?.software.id
    }

    func recordingFolders(for appID: String) -> [URL] {
        let configured = folderAccesses
            .filter { $0.appID == appID && $0.kind == .recordings }
            .map { folderAccessStore.resolve($0) }

        let discovered = probeResults
            .first { $0.software.id == appID }?
            .existingRecordingURLs ?? []

        return configured + discovered
    }

    func historyFolders(for appID: String) -> [URL] {
        let configured = folderAccesses
            .filter { $0.appID == appID && $0.kind == .history }
            .map { folderAccessStore.resolve($0) }

        let discovered = probeResults
            .first { $0.software.id == appID }?
            .existingHistoryURLs ?? []

        return configured + discovered
    }

    func chooseFolder(appID: String, kind: FolderKind) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.title = kind == .recordings ? "Set Recording Folder" : "Set History Folder"
        panel.message = kind == .recordings
            ? "Choose the folder where this DJ app saves recordings."
            : "Choose the folder where this DJ app saves history or exports."
        panel.directoryURL = defaultFolderPanelURL(appID: appID, kind: kind)

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let bookmark = try folderAccessStore.makeBookmarkData(for: url)
            let access = FolderAccess(appID: appID, kind: kind, url: url, bookmarkData: bookmark)
            try folderAccessStore.save(access)
            refresh()
            statusMessage = "Saved \(kind.displayName.lowercased()) folder for \(displayName(for: appID))"
        } catch {
            appendActivity(kind: .error, message: "Folder access save failed", detail: error.localizedDescription)
            statusMessage = "Could not save folder access: \(error.localizedDescription)"
        }
    }

    func clearFolder(appID: String, kind: FolderKind) {
        do {
            try folderAccessStore.remove(appID: appID, kind: kind)
            refresh()
        } catch {
            statusMessage = "Could not remove folder access: \(error.localizedDescription)"
        }
    }

    func importHistory(appID: String) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            .commaSeparatedText,
            .tabSeparatedText,
            .plainText,
            .xml,
            UTType(filenameExtension: "nml") ?? .xml
        ]
        panel.prompt = "Import"
        panel.message = "Choose a history export or tracklist file."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let parser = parserForHistory(appID: appID)
            let tracks = try parser.parse(data: data, sourceName: url.lastPathComponent)
            let importedTracklist = ImportedTracklist(
                appID: appID,
                sourceURL: url,
                kind: tracklistKind(appID: appID, sourceURL: url),
                tracks: tracks
            )
            try importedTracklistStore.save(importedTracklist)
            try activityLogStore.append(ActivityEvent(
                kind: .importTracklist,
                message: "Imported \(tracks.count) tracks",
                detail: url.lastPathComponent
            ))
            refresh()
            statusMessage = "Imported \(tracks.count) track\(tracks.count == 1 ? "" : "s") from \(url.lastPathComponent)"
        } catch {
            appendActivity(kind: .error, message: "History import failed", detail: error.localizedDescription)
            statusMessage = "Could not import history: \(error.localizedDescription)"
        }
    }

    func deleteImportedTracklist(id: UUID) {
        do {
            try importedTracklistStore.remove(id: id)
            try activityLogStore.append(ActivityEvent(kind: .importTracklist, message: "Deleted imported tracklist"))
            refresh()
        } catch {
            appendActivity(kind: .error, message: "Delete import failed", detail: error.localizedDescription)
            statusMessage = "Could not delete import: \(error.localizedDescription)"
        }
    }

    func scanNow() {
        guard !isScanning else { return }

        isScanning = true
        let requests = scanRequests()
        let coordinator = scanCoordinator()

        Task {
            let results = await Task.detached(priority: .userInitiated) {
                coordinator.scanRecent(requests: requests)
            }.value

            await MainActor.run {
                lastScanResults = results
                isScanning = false
                appendScanActivity(results)
                refresh()
                statusMessage = scanStatusMessage(for: results)
            }
        }
    }

    func clearActivity() {
        do {
            try activityLogStore.clear()
            refresh()
        } catch {
            statusMessage = "Could not clear activity: \(error.localizedDescription)"
        }
    }

    func updateAutomaticScanning(enabled: Bool) {
        saveSettings(AppSettings(
            automaticScanningEnabled: enabled,
            scanIntervalSeconds: settings.scanIntervalSeconds,
            archiveNamingTemplate: settings.archiveNamingTemplate
        ))
    }

    func updateScanInterval(seconds: Int) {
        saveSettings(AppSettings(
            automaticScanningEnabled: settings.automaticScanningEnabled,
            scanIntervalSeconds: seconds,
            archiveNamingTemplate: settings.archiveNamingTemplate
        ))
    }

    func updateArchiveNamingTemplate(_ template: String) {
        saveSettings(AppSettings(
            automaticScanningEnabled: settings.automaticScanningEnabled,
            scanIntervalSeconds: settings.scanIntervalSeconds,
            archiveNamingTemplate: template
        ))
    }

    func exportDiagnostics() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "DJMemory-Diagnostics-\(diagnosticsTimestamp()).json"
        panel.message = "Save a diagnostics report with setup, archive, import, and recent activity counts."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let report = DiagnosticsReportBuilder().build(
                archiveRoot: archiveRoot,
                probeResults: probeResults,
                recordingFolders: { [weak self] appID in self?.recordingFolders(for: appID) ?? [] },
                historyFolders: { [weak self] appID in self?.historyFolders(for: appID) ?? [] },
                folderAccesses: folderAccesses,
                archives: sessions,
                importedTracklists: allImportedTracklists,
                activityEvents: activityEvents
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            encoder.dateEncodingStrategy = .iso8601

            try encoder.encode(report).write(to: url, options: .atomic)
            try activityLogStore.append(ActivityEvent(
                kind: .scan,
                message: "Exported diagnostics",
                detail: url.path
            ))
            refresh()
            revealInFinder(url)
            statusMessage = "Diagnostics saved to \(url.lastPathComponent)"
        } catch {
            appendActivity(kind: .error, message: "Diagnostics export failed", detail: error.localizedDescription)
            statusMessage = "Could not export diagnostics: \(error.localizedDescription)"
        }
    }

    func scanResults(for appID: String) -> [FolderScanResult] {
        lastScanResults.filter { $0.appID == appID }
    }

    func setupState(for result: SoftwareProbeResult) -> String {
        let appScanResults = scanResults(for: result.software.id)

        if appScanResults.contains(where: { $0.errorDescription != nil }) {
            return "Error"
        }

        if appScanResults.contains(where: { !$0.archivedSessions.isEmpty }) {
            return "Archived"
        }

        if recordingFolders(for: result.software.id).isEmpty {
            return result.installedApplicationURLs.isEmpty ? "App not found" : "Needs folder access"
        }

        return isScanning ? "Scanning" : "Watching"
    }

    func importedTracklists(for appID: String) -> [ImportedTracklist] {
        importedTracklists[appID] ?? []
    }

    func displayName(for appID: String) -> String {
        probeResults.first { $0.software.id == appID }?.software.displayName
            ?? SupportedDJSoftware.all.first { $0.id == appID }?.displayName
            ?? appID
    }

    var allImportedTracklists: [ImportedTracklist] {
        importedTracklists.values.flatMap { $0 }.sorted { $0.importedAt > $1.importedAt }
    }

    func revealInFinder(_ url: URL) {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }

    func openArchiveFolder() {
        do {
            try FileManager.default.createDirectory(at: archiveRoot, withIntermediateDirectories: true)
            NSWorkspace.shared.open(archiveRoot)
        } catch {
            statusMessage = "Could not open archive folder: \(error.localizedDescription)"
        }
    }

    private func startBackgroundScanning() {
        scanTask?.cancel()
        guard settings.automaticScanningEnabled else {
            scanTask = nil
            return
        }

        let intervalSeconds = settings.scanIntervalSeconds
        scanTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(intervalSeconds))
                self?.scanNow()
            }
        }
    }

    private func scanRequests() -> [FolderScanRequest] {
        probeResults.flatMap { result -> [FolderScanRequest] in
            let configured = folderAccesses
                .filter { $0.appID == result.software.id && $0.kind == .recordings }
                .map { access in
                    FolderScanRequest(
                        appID: result.software.id,
                        folderURL: folderAccessStore.resolve(access),
                        bookmarkData: access.bookmarkData
                    )
                }

            let configuredPaths = Set(configured.map(\.folderURL.path))
            let discovered = result.existingRecordingURLs
                .filter { !configuredPaths.contains($0.path) }
                .map { FolderScanRequest(appID: result.software.id, folderURL: $0) }

            return configured + discovered
        }
    }

    private func defaultFolderPanelURL(appID: String, kind: FolderKind) -> URL? {
        switch kind {
        case .recordings:
            return recordingFolders(for: appID).first
        case .history:
            return historyFolders(for: appID).first
        }
    }

    private func scanCoordinator() -> ScanCoordinator {
        let archiveService = ArchiveService(namingTemplate: settings.archiveNamingTemplate)
        let scanner = RecordingFolderScanner(archiveService: archiveService)
        return ScanCoordinator(scanner: scanner)
    }

    private func scanStatusMessage(for results: [FolderScanResult]) -> String {
        guard !results.isEmpty else {
            return "Choose recording folders to start protecting sets"
        }

        let archivedCount = results.reduce(0) { $0 + $1.archivedSessions.count }
        let errorCount = results.filter { $0.errorDescription != nil }.count

        if archivedCount > 0 {
            return "Archived \(archivedCount) set\(archivedCount == 1 ? "" : "s")"
        }

        if errorCount > 0 {
            return "\(errorCount) folder\(errorCount == 1 ? "" : "s") need attention"
        }

        return "Scan complete. No new recordings found."
    }

    private func appendScanActivity(_ results: [FolderScanResult]) {
        guard !results.isEmpty else {
            appendActivity(kind: .scan, message: "Scan skipped", detail: "No recording folders configured")
            return
        }

        for result in results {
            if let errorDescription = result.errorDescription {
                appendActivity(kind: .error, message: "Scan failed", detail: "\(result.folderURL.path): \(errorDescription)")
            } else if result.archivedSessions.isEmpty {
                appendActivity(kind: .scan, message: "No new recordings", detail: result.folderURL.path)
            } else {
                appendActivity(
                    kind: .archive,
                    message: "Archived \(result.archivedSessions.count) recording\(result.archivedSessions.count == 1 ? "" : "s")",
                    detail: result.folderURL.path
                )
                notificationService.notifyArchiveSaved(count: result.archivedSessions.count)
            }
        }
    }

    private func appendActivity(kind: ActivityEventKind, message: String, detail: String? = nil) {
        do {
            try activityLogStore.append(ActivityEvent(kind: kind, message: message, detail: detail))
            activityEvents = (try? activityLogStore.all()) ?? activityEvents
        } catch {
            statusMessage = "Could not write activity: \(error.localizedDescription)"
        }
    }

    private func saveSettings(_ newSettings: AppSettings) {
        do {
            try appSettingsStore.save(newSettings)
            settings = newSettings
            startBackgroundScanning()
            statusMessage = newSettings.automaticScanningEnabled
                ? "Automatic scan runs every \(newSettings.scanIntervalSeconds) seconds"
                : "Automatic scan is off"
        } catch {
            appendActivity(kind: .error, message: "Settings save failed", detail: error.localizedDescription)
            statusMessage = "Could not save settings: \(error.localizedDescription)"
        }
    }

    private func diagnosticsTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }

    private func parserForHistory(appID: String) -> TracklistParser {
        switch appID {
        case "serato":
            return SeratoHistoryParser()
        case "rekordbox":
            return RekordboxXMLParser()
        case "traktor":
            return TraktorNMLParser()
        default:
            return DelimitedTracklistParser()
        }
    }

    private func tracklistKind(appID: String, sourceURL: URL) -> ImportedTracklistKind {
        if appID == "rekordbox", sourceURL.pathExtension.localizedCaseInsensitiveCompare("xml") == .orderedSame {
            return .collection
        }

        return .setHistory
    }
}
