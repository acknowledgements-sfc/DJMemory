import Foundation
import DJMemoryCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var probeResults: [SoftwareProbeResult] = []
    @Published private(set) var sessions: [ArchiveMetadata] = []
    @Published var selectedAppID: String?
    @Published var statusMessage = "Checking protection status"

    let archiveRoot = ArchiveService.defaultArchiveRoot()
    private let probe = SoftwareProbe()
    private let library = SessionLibrary()

    init() {
        refresh()
    }

    var protectedAdapterCount: Int {
        probeResults.filter { !$0.existingRecordingURLs.isEmpty || $0.software.id == "rekordbox" }.count
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

        if protectedAdapterCount > 0 {
            statusMessage = "\(protectedAdapterCount) source\(protectedAdapterCount == 1 ? "" : "s") ready"
        } else {
            statusMessage = "Choose recording folders to start protecting sets"
        }

        selectedAppID = selectedAppID ?? probeResults.first?.software.id
    }
}
