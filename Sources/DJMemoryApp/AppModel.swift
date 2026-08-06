import AppKit
import Foundation
import DJMemoryCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var probeResults: [SoftwareProbeResult] = []
    @Published private(set) var sessions: [ArchiveMetadata] = []
    @Published private(set) var folderAccesses: [FolderAccess] = []
    @Published private(set) var lastScanResults: [FolderScanResult] = []
    @Published private(set) var importedTracklists: [String: ImportedTracklist] = [:]
    @Published private(set) var isScanning = false
    @Published var selectedAppID: String?
    @Published var statusMessage = "Checking protection status"

    let archiveRoot = ArchiveService.defaultArchiveRoot()
    private let probe = SoftwareProbe()
    private let library = SessionLibrary()
    private let folderAccessStore = FolderAccessStore()
    private let importedTracklistStore = ImportedTracklistStore()
    private var scanTask: Task<Void, Never>?

    init() {
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
        ).compactMapValues { $0.sorted { $0.importedAt > $1.importedAt }.first }

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
        panel.message = kind == .recordings
            ? "Choose the folder where this DJ app saves recordings."
            : "Choose the folder where this DJ app saves history or exports."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let bookmark = try folderAccessStore.makeBookmarkData(for: url)
            let access = FolderAccess(appID: appID, kind: kind, url: url, bookmarkData: bookmark)
            try folderAccessStore.save(access)
            refresh()
        } catch {
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
        panel.allowedContentTypes = [.commaSeparatedText, .tabSeparatedText, .plainText, .xml]
        panel.prompt = "Import"
        panel.message = "Choose a history export or tracklist file."

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let parser = parserForHistory(appID: appID)
            let tracks = try parser.parse(data: data, sourceName: url.lastPathComponent)
            let importedTracklist = ImportedTracklist(appID: appID, sourceURL: url, tracks: tracks)
            try importedTracklistStore.save(importedTracklist)
            importedTracklists[appID] = importedTracklist
            statusMessage = "Imported \(tracks.count) track\(tracks.count == 1 ? "" : "s") from \(url.lastPathComponent)"
        } catch {
            statusMessage = "Could not import history: \(error.localizedDescription)"
        }
    }

    func scanNow() {
        guard !isScanning else { return }

        isScanning = true
        let requests = scanRequests()

        Task {
            let results = await Task.detached(priority: .userInitiated) {
                ScanCoordinator().scanRecent(requests: requests)
            }.value

            await MainActor.run {
                lastScanResults = results
                isScanning = false
                refresh()
                statusMessage = scanStatusMessage(for: results)
            }
        }
    }

    func scanResults(for appID: String) -> [FolderScanResult] {
        lastScanResults.filter { $0.appID == appID }
    }

    func importedTracklist(for appID: String) -> ImportedTracklist? {
        importedTracklists[appID]
    }

    private func startBackgroundScanning() {
        scanTask?.cancel()
        scanTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                self?.scanNow()
            }
        }
    }

    private func scanRequests() -> [FolderScanRequest] {
        probeResults.flatMap { result in
            recordingFolders(for: result.software.id).map { folderURL in
                FolderScanRequest(appID: result.software.id, folderURL: folderURL)
            }
        }
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

    private func parserForHistory(appID: String) -> TracklistParser {
        switch appID {
        case "serato":
            return SeratoHistoryParser()
        default:
            return DelimitedTracklistParser()
        }
    }
}
