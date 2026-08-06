import AppKit
import Foundation
import DJMemoryCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var probeResults: [SoftwareProbeResult] = []
    @Published private(set) var sessions: [ArchiveMetadata] = []
    @Published private(set) var folderAccesses: [FolderAccess] = []
    @Published var selectedAppID: String?
    @Published var statusMessage = "Checking protection status"

    let archiveRoot = ArchiveService.defaultArchiveRoot()
    private let probe = SoftwareProbe()
    private let library = SessionLibrary()
    private let folderAccessStore = FolderAccessStore()

    init() {
        refresh()
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
}
