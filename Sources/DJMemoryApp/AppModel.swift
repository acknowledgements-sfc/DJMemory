import AppKit
import Foundation
import ServiceManagement
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
    @Published private(set) var setContexts: [UUID: SetContext] = [:]
    @Published private(set) var activityEvents: [ActivityEvent] = []
    @Published private(set) var settings = AppSettings.default
    @Published private(set) var virtualDJNetworkProbeResult: VirtualDJNetworkProbeResult?
    @Published private(set) var isCheckingVirtualDJNetwork = false
    @Published private(set) var isScanning = false
    @Published private(set) var isFolderChangeScanPending = false
    @Published private(set) var lastScanDate: Date?
    @Published private(set) var nextScanDate: Date?
    @Published var selectedRoute: Route = .home
    @Published var statusMessage = "Checking protection status"
    @Published private(set) var profile = DJProfile()
    /// True when macOS registered the login item but still needs Login Items approval.
    @Published private(set) var launchAtLoginNeedsApproval = false
    @Published private(set) var captureState = CaptureUIState()
    @Published private(set) var virtualDJNetworkCommandResult: VirtualDJNetworkCommandResult?

    /// Consumed by `SessionLibraryView` when navigating from Home (session + optional search seed).
    @Published var libraryFocusSessionID: UUID?
    @Published var libraryFocusSearch: String = ""

    /// Preview-only clock override for greeting matrix (morning / afternoon / evening).
    @Published private(set) var previewNow: Date?

    func openLibrary(sessionID: UUID? = nil, search: String = "") {
        libraryFocusSessionID = sessionID
        libraryFocusSearch = search
        selectedRoute = .library
    }

    func consumeLibraryFocus() -> (sessionID: UUID?, search: String) {
        let focus = (libraryFocusSessionID, libraryFocusSearch)
        libraryFocusSessionID = nil
        libraryFocusSearch = ""
        return focus
    }

    /// App id when `selectedRoute` is `.app` or `.recovery`.
    var selectedAppID: String? {
        selectedRoute.appID
    }

    var archiveRoot: URL {
        resolvedArchiveRoot()
    }

    var libraryStatistics: LibraryStatistics {
        LibraryStatisticsCalculator.calculate(archives: sessions, summaries: librarySummaries)
    }

    var topTracks: [TrackPlayCount] {
        CrossSetAggregation.topTracks(from: allImportedTracklists)
    }

    var venueCounts: [VenueCount] {
        CrossSetAggregation.venues(from: Array(setContexts.values))
    }

    var tagCounts: [TagCount] {
        CrossSetAggregation.tags(from: Array(setContexts.values))
    }

    private let probe = SoftwareProbe()
    private let folderAccessStore = FolderAccessStore()
    private let importedTracklistStore = ImportedTracklistStore()
    private let setContextStore = SetContextStore()
    private let activityLogStore = ActivityLogStore()
    private let appSettingsStore = AppSettingsStore()
    private let profileStore = DJProfileStore()
    private let notificationService = LocalNotificationService()
    private let folderChangeMonitor = FolderChangeMonitor()
    let captureService = CaptureService()
    private var scanTask: Task<Void, Never>?
    private var folderChangeScanTask: Task<Void, Never>?
    var captureMeterTask: Task<Void, Never>?
    /// When true, profile mutations stay in memory (SwiftUI previews).
    private var suppressProfilePersistence = false

    init() {
        notificationService.requestAuthorization()
        refresh()
        startBackgroundScanning()
    }

    deinit {
        scanTask?.cancel()
        folderChangeScanTask?.cancel()
        captureMeterTask?.cancel()
        folderChangeMonitor.stop()
    }

    var protectedAdapterCount: Int {
        probeResults.filter { result in
            !reachableRecordingFolders(for: result.software.id).isEmpty
        }.count
    }

    var protectionSymbolName: String {
        switch protectionState {
        case .protected, .scanning:
            return "record.circle.fill"
        case .needsSetup:
            return "record.circle"
        case .attentionNeeded:
            return "exclamationmark.triangle.fill"
        }
    }

    var protectionState: ProtectionState {
        let hasConfigured = folderAccesses.contains { $0.kind == .recordings }
        let hasUnreachable = folderAccesses.contains { access in
            access.kind == .recordings && !folderAccessStore.isReachable(access)
        }
        return ProtectionState.derive(
            isScanning: isScanning,
            hasUnreachableFolder: hasUnreachable,
            hasConfiguredRecordingsFolder: hasConfigured
        )
    }

    var headlineStatus: String {
        protectionState.headline
    }

    var lastScanDisplayText: String {
        guard let lastScanDate else {
            return "Not yet"
        }

        return lastScanDate.formatted(date: .omitted, time: .shortened)
    }

    var nextScanDisplayText: String {
        guard settings.automaticScanningEnabled else {
            return "Off"
        }

        if isScanning {
            return "Scanning now"
        }

        if isFolderChangeScanPending {
            return "Soon"
        }

        guard let nextScanDate else {
            return "Pending"
        }

        return nextScanDate.formatted(date: .omitted, time: .shortened)
    }

    var scanScheduleDisplayText: String {
        if settings.automaticScanningEnabled {
            return "Every \(settings.scanIntervalSeconds) seconds"
        }

        return "Automatic scanning is off"
    }

    func refresh() {
        probeResults = probe.probeAll()
        folderAccesses = (try? folderAccessStore.all()) ?? []
        settings = (try? appSettingsStore.load()) ?? .default
        ensureArchiveRootExists()
        sessions = (try? sessionLibrary().archivedMetadata()) ?? []
        importedTracklists = Dictionary(
            grouping: (try? importedTracklistStore.all()) ?? [],
            by: \.appID
        ).mapValues { $0.sorted { $0.importedAt > $1.importedAt } }
        setContexts = Dictionary(
            uniqueKeysWithValues: ((try? setContextStore.all()) ?? []).map { ($0.sessionID, $0) }
        )
        librarySummaries = LibrarySessionMatcher().summaries(
            archives: sessions,
            importedTracklists: importedTracklists.values.flatMap { $0 },
            setContexts: Array(setContexts.values)
        )
        activityEvents = (try? activityLogStore.all()) ?? []
        profile = (try? profileStore.load()) ?? DJProfile()
        reconcileLaunchAtLogin()

        if protectedAdapterCount > 0 {
            statusMessage = "\(protectedAdapterCount) source\(protectedAdapterCount == 1 ? "" : "s") ready"
        } else {
            statusMessage = "Choose recording folders to start protecting sets"
        }

        restartFolderChangeMonitoring()
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

    /// User-chosen recordings folder via security-scoped `FolderAccess` (HANDOFF-2 §4.10).
    func hasConfiguredRecordingsFolder(appID: String) -> Bool {
        folderAccesses.contains { $0.appID == appID && $0.kind == .recordings }
    }

    var configuredProbeResults: [SoftwareProbeResult] {
        probeResults.filter { hasConfiguredRecordingsFolder(appID: $0.software.id) }
    }

    var unconfiguredProbeResults: [SoftwareProbeResult] {
        probeResults.filter {
            $0.software.id != SupportedDJSoftware.captureAppID
                && !hasConfiguredRecordingsFolder(appID: $0.software.id)
        }
    }

    /// Configured recordings folder exists but none of its resolved URLs are reachable.
    func isConfiguredRecordingsFolderUnreachable(appID: String) -> Bool {
        let configuredURLs = folderAccesses
            .filter { $0.appID == appID && $0.kind == .recordings }
            .map { folderAccessStore.resolve($0) }

        guard !configuredURLs.isEmpty else {
            return false
        }

        return !configuredURLs.contains(where: isReachableDirectory(_:))
    }

    func isFolderAccessReachable(_ access: FolderAccess) -> Bool {
        folderAccessStore.isReachable(access)
    }

    func unreachableRecordingAccesses() -> [FolderAccess] {
        folderAccesses.filter { $0.kind == .recordings && !folderAccessStore.isReachable($0) }
    }

    func reachableRecordingFolders(for appID: String) -> [URL] {
        recordingFolders(for: appID).filter(isReachableDirectory(_:))
    }

    /// Preview / test helper — does not persist. Seeds `FolderAccess` rows for sidebar matrix previews.
    func previewApplyConfiguredRecordingsFolders(
        reachableAppIDs: [String],
        unreachableAppIDs: [String] = []
    ) {
        var accesses: [FolderAccess] = []

        for appID in reachableAppIDs {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("djmemory-preview-\(appID)", isDirectory: true)
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            accesses.append(
                FolderAccess(appID: appID, kind: .recordings, url: url, bookmarkData: nil)
            )
        }

        for appID in unreachableAppIDs {
            let url = URL(fileURLWithPath: "/Volumes/MissingDrive-\(appID)/Recordings", isDirectory: true)
            accesses.append(
                FolderAccess(appID: appID, kind: .recordings, url: url, bookmarkData: nil)
            )
        }

        folderAccesses = accesses
    }

    /// Preview / test helper — does not persist.
    func previewSetScanning(_ scanning: Bool) {
        isScanning = scanning
    }

    /// Preview / test helper — does not persist.
    func previewApplyProfile(_ profile: DJProfile) {
        self.profile = profile
        suppressProfilePersistence = true
    }

    /// Preview / test helper — forces greeting hour without waiting for wall clock.
    func previewApplyNow(_ date: Date?) {
        previewNow = date
    }

    /// Preview / test helper — does not persist. Seeds library surfaces for Home / Library / Activity.
    func previewApplyLibrary(
        archives: [ArchiveMetadata] = [],
        summaries: [LibrarySessionSummary] = [],
        activity: [ActivityEvent] = [],
        imported: [ImportedTracklist] = [],
        contexts: [SetContext] = []
    ) {
        sessions = archives
        librarySummaries = summaries.isEmpty
            ? archives.map { LibrarySessionSummary(archive: $0, matchedTracklist: nil) }
            : summaries
        activityEvents = activity
        importedTracklists = Dictionary(grouping: imported, by: \.appID)
        setContexts = Dictionary(uniqueKeysWithValues: contexts.map { ($0.sessionID, $0) })
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
            ? (appID == SupportedDJSoftware.pioneerHardwareAppID
                ? "Choose the USB stick or PIONEERREC folder where MASTER REC writes RECxxx.WAV files."
                : "Choose the folder where this DJ app saves recordings.")
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
            UTType(filenameExtension: "nml") ?? .xml,
            UTType(filenameExtension: "m3u") ?? .plainText,
            UTType(filenameExtension: "m3u8") ?? .plainText,
            UTType(filenameExtension: "vdjfolder") ?? .xml
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

    func saveSetContext(_ context: SetContext) {
        do {
            try setContextStore.save(context)
            try activityLogStore.append(ActivityEvent(
                kind: .scan,
                message: "Updated set details",
                detail: context.eventName.isEmpty ? nil : context.eventName
            ))
            refresh()
            statusMessage = "Set details saved"
        } catch {
            appendActivity(kind: .error, message: "Set details save failed", detail: error.localizedDescription)
            statusMessage = "Could not save set details: \(error.localizedDescription)"
        }
    }

    func attachTracklist(sessionID: UUID, tracklistID: UUID?) {
        do {
            var context = try setContextStore.context(for: sessionID)
            context.manualTracklistID = tracklistID
            try setContextStore.save(context)
            try activityLogStore.append(ActivityEvent(
                kind: .importTracklist,
                message: tracklistID == nil ? "Detached tracklist" : "Attached tracklist"
            ))
            refresh()
            statusMessage = tracklistID == nil ? "Tracklist detached" : "Tracklist attached"
        } catch {
            appendActivity(kind: .error, message: "Tracklist attachment failed", detail: error.localizedDescription)
            statusMessage = "Could not update tracklist match: \(error.localizedDescription)"
        }
    }

    func scanNow() {
        guard !isScanning else { return }

        isScanning = true
        isFolderChangeScanPending = false
        nextScanDate = nil
        let requests = scanRequests()
        let coordinator = scanCoordinator()

        Task {
            let results = await Task.detached(priority: .userInitiated) {
                coordinator.scanRecent(requests: requests)
            }.value

            await MainActor.run {
                lastScanResults = results
                lastScanDate = Date()
                isScanning = false
                appendScanActivity(results)
                refresh()
                scheduleNextScanIfNeeded()
                statusMessage = scanStatusMessage(for: results)
            }
        }
    }

    func checkVirtualDJNetworkControl() {
        guard !isCheckingVirtualDJNetwork else { return }

        isCheckingVirtualDJNetwork = true
        statusMessage = "Checking VirtualDJ Network Control"

        Task {
            let result = await VirtualDJNetworkProbe().probe()

            await MainActor.run {
                virtualDJNetworkProbeResult = result
                isCheckingVirtualDJNetwork = false
                appendActivity(
                    kind: result.reachable ? .scan : .error,
                    message: result.reachable ? "VirtualDJ Network Control reachable" : "VirtualDJ Network Control not reachable",
                    detail: result.errorDescription ?? result.endpoint.absoluteString
                )
                statusMessage = result.reachable
                    ? "VirtualDJ Network Control is reachable"
                    : "VirtualDJ Network Control is not reachable"
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
        saveSettings(settings.updating(automaticScanningEnabled: enabled))
    }

    func updateScanInterval(seconds: Int) {
        saveSettings(settings.updating(scanIntervalSeconds: seconds))
    }

    func updateArchiveNamingTemplate(_ template: String) {
        saveSettings(settings.updating(archiveNamingTemplate: template))
    }

    func updateVerifyCopies(enabled: Bool) {
        saveSettings(settings.updating(verifyCopies: enabled))
    }

    func updateNotifyAfterArchiving(enabled: Bool) {
        saveSettings(settings.updating(notifyAfterArchiving: enabled))
    }

    func updateLaunchAtLogin(enabled: Bool) {
        applyLaunchAtLogin(enabled: enabled, persistPreference: true)
    }

    /// Saves local DJ identity for Home. Blank strings become nil — never invent placeholders.
    func updateProfile(displayName: String, handle: String, city: String, residency: String) {
        var next = DJProfile(
            displayName: Self.nilIfBlank(displayName),
            handle: Self.nilIfBlank(handle),
            city: Self.nilIfBlank(city),
            residency: Self.nilIfBlank(residency),
            memberSince: profile.memberSince
        )

        let hasIdentity = next.displayName != nil
            || next.handle != nil
            || next.city != nil
            || next.residency != nil
        if hasIdentity, next.memberSince == nil {
            next.memberSince = Date()
        }
        if !hasIdentity {
            next.memberSince = nil
        }

        do {
            if !suppressProfilePersistence {
                try profileStore.save(next)
            }
            profile = next
            statusMessage = hasIdentity ? "Profile saved" : "Profile cleared"
        } catch {
            appendActivity(kind: .error, message: "Profile save failed", detail: error.localizedDescription)
            statusMessage = "Could not save profile: \(error.localizedDescription)"
        }
    }

    func openLoginItemsSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func completeOnboarding(destination: Route = .protection) {
        saveSettings(settings.updating(hasCompletedOnboarding: true))
        selectedRoute = destination
        statusMessage = protectedAdapterCount > 0
            ? "\(protectedAdapterCount) source\(protectedAdapterCount == 1 ? "" : "s") ready"
            : "Choose recording folders to start protecting sets"
    }

    /// Compatibility shim for call sites that still pass a destination string tag.
    func completeOnboarding(destinationAppID: String) {
        completeOnboarding(destination: Self.route(fromLegacySelection: destinationAppID))
    }

    func showOnboardingAgain() {
        saveSettings(settings.updating(hasCompletedOnboarding: false))
        selectedRoute = .protection
    }

    static func route(fromLegacySelection id: String) -> Route {
        switch id {
        case "home":
            return .home
        case "protection":
            return .protection
        case "library":
            return .library
        case "activity":
            return .activity
        case "settings":
            return .settings
        default:
            return .app(id)
        }
    }

    func chooseArchiveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Choose"
        panel.title = "Set Archive Folder"
        panel.message = "Choose where DJMemory stores protected recording copies."
        panel.directoryURL = archiveRoot

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            let bookmark = try folderAccessStore.makeBookmarkData(for: url)
            saveSettings(settings.updating(
                archiveRootPath: .some(url.path),
                archiveRootBookmarkData: .some(bookmark)
            ))
            refresh()
            statusMessage = "Archive folder set to \(url.lastPathComponent)"
        } catch {
            appendActivity(kind: .error, message: "Archive folder save failed", detail: error.localizedDescription)
            statusMessage = "Could not save archive folder: \(error.localizedDescription)"
        }
    }

    func resetArchiveFolder() {
        saveSettings(settings.updating(
            archiveRootPath: .some(nil),
            archiveRootBookmarkData: .some(nil)
        ))
        refresh()
        statusMessage = "Archive folder reset to ~/Music/DJMemory"
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
                kind: .diagnostics,
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

    func setupState(for result: SoftwareProbeResult) -> AppSetupState {
        let appScanResults = scanResults(for: result.software.id)

        if appScanResults.contains(where: { $0.errorDescription != nil }) {
            return .error
        }

        if appScanResults.contains(where: { !$0.pendingRecordingURLs.isEmpty }) {
            return .recordingDetected
        }

        if appScanResults.contains(where: { !$0.archivedSessions.isEmpty }) {
            return .archived
        }

        let recordingFolders = recordingFolders(for: result.software.id)
        if recordingFolders.isEmpty {
            let hasNoInstallableApp = result.software.bundleIdentifiers.isEmpty
                || (result.installedApplicationURLs.isEmpty && !result.isRunning)
            return hasNoInstallableApp && !result.software.bundleIdentifiers.isEmpty
                ? .appNotFound
                : .needsFolderAccess
        }

        if !recordingFolders.contains(where: isReachableDirectory(_:)) {
            return .attentionNeeded
        }

        if isScanning {
            return .saving
        }

        if hasRecentUnstableRecording(for: result.software.id) {
            return .recordingDetected
        }

        return .watching
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
            try archiveService().ensureArchiveRootExists()
            NSWorkspace.shared.open(archiveRoot)
        } catch {
            statusMessage = "Could not open archive folder: \(error.localizedDescription)"
        }
    }

    private func startBackgroundScanning() {
        scanTask?.cancel()
        guard settings.automaticScanningEnabled else {
            scanTask = nil
            folderChangeScanTask?.cancel()
            isFolderChangeScanPending = false
            nextScanDate = nil
            folderChangeMonitor.stop()
            return
        }

        let intervalSeconds = settings.scanIntervalSeconds
        scheduleNextScanIfNeeded()
        restartFolderChangeMonitoring()
        scanTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(intervalSeconds))
                self?.scanNow()
            }
        }
    }

    private func restartFolderChangeMonitoring() {
        guard settings.automaticScanningEnabled else {
            folderChangeMonitor.stop()
            return
        }

        folderChangeMonitor.start(requests: scanRequests()) { [weak self] in
            Task { @MainActor in
                self?.scheduleFolderChangeScan()
            }
        }
    }

    private func scheduleFolderChangeScan() {
        guard settings.automaticScanningEnabled else { return }

        folderChangeScanTask?.cancel()
        isFolderChangeScanPending = true
        nextScanDate = Date().addingTimeInterval(5)
        statusMessage = "Recording folder changed; scanning soon"

        folderChangeScanTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            await MainActor.run {
                guard let self, !Task.isCancelled else { return }
                self.isFolderChangeScanPending = false
                self.scanNow()
            }
        }
    }

    private func scheduleNextScanIfNeeded() {
        nextScanDate = settings.automaticScanningEnabled
            ? Date().addingTimeInterval(TimeInterval(settings.scanIntervalSeconds))
            : nil
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

    private func hasRecentUnstableRecording(for appID: String, now: Date = Date()) -> Bool {
        let checker = FileStabilityChecker()
        let cutoff = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? .distantPast
        let unstableAfter = now.addingTimeInterval(-30)

        return scanRequests()
            .filter { $0.appID == appID }
            .contains { request in
                (try? withSecurityScopedFolder(request) { folderURL in
                    try !checker.recentUnstableAudioFiles(
                        in: folderURL,
                        modifiedAfter: cutoff,
                        unstableAfter: unstableAfter
                    ).isEmpty
                }) ?? false
            }
    }

    private func isReachableDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    private func withSecurityScopedFolder<T>(
        _ request: FolderScanRequest,
        operation: (URL) throws -> T
    ) throws -> T {
        guard let bookmarkData = request.bookmarkData else {
            return try operation(request.folderURL)
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        guard !isStale else {
            return try operation(request.folderURL)
        }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation(url)
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
        let scanner = RecordingFolderScanner(archiveService: archiveService())
        return ScanCoordinator(scanner: scanner)
    }

    private func archiveService() -> ArchiveService {
        ArchiveService(
            archiveRoot: archiveRoot,
            namingTemplate: settings.archiveNamingTemplate,
            archiveRootBookmarkData: settings.archiveRootBookmarkData
        )
    }

    private func sessionLibrary() -> SessionLibrary {
        SessionLibrary(
            archiveRoot: archiveRoot,
            archiveRootBookmarkData: settings.archiveRootBookmarkData
        )
    }

    private func ensureArchiveRootExists() {
        do {
            try archiveService().ensureArchiveRootExists()
        } catch {
            appendActivity(kind: .error, message: "Archive folder unavailable", detail: error.localizedDescription)
        }
    }

    private func resolvedArchiveRoot() -> URL {
        if let bookmarkData = settings.archiveRootBookmarkData {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), !isStale {
                return url
            }
        }

        if let archiveRootPath = settings.archiveRootPath, !archiveRootPath.isEmpty {
            return URL(fileURLWithPath: (archiveRootPath as NSString).expandingTildeInPath, isDirectory: true)
        }

        return ArchiveService.defaultArchiveRoot()
    }

    private func withSecurityScopedArchiveRoot<T>(_ operation: () throws -> T) rethrows -> T {
        guard let bookmarkData = settings.archiveRootBookmarkData else {
            return try operation()
        }

        var isStale = false
        guard
            let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ),
            !isStale
        else {
            return try operation()
        }

        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation()
    }

    private func scanStatusMessage(for results: [FolderScanResult]) -> String {
        guard !results.isEmpty else {
            return "Choose recording folders to start protecting sets"
        }

        let archivedCount = results.reduce(0) { $0 + $1.archivedSessions.count }
        let pendingCount = results.reduce(0) { $0 + $1.pendingRecordingURLs.count }
        let errorCount = results.filter { $0.errorDescription != nil }.count

        if pendingCount > 0 {
            return "Detected \(pendingCount) active recording\(pendingCount == 1 ? "" : "s"). Waiting for file to finish."
        }

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
            } else if !result.pendingRecordingURLs.isEmpty {
                appendActivity(
                    kind: .scan,
                    message: "Recording detected",
                    detail: pendingRecordingDetail(for: result)
                )
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

    private func pendingRecordingDetail(for result: FolderScanResult) -> String {
        let names = result.pendingRecordingURLs
            .map(\.lastPathComponent)
            .joined(separator: ", ")
        return "\(result.folderURL.path): waiting for \(names)"
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

    private func reconcileLaunchAtLogin() {
        let status = SMAppService.mainApp.status
        launchAtLoginNeedsApproval = status == .requiresApproval
        let osEnabled = status == .enabled

        if settings.launchAtLogin == osEnabled {
            return
        }

        if settings.launchAtLogin, !osEnabled {
            // Prefer the saved preference; do not clear it if registration fails outside a real .app bundle.
            applyLaunchAtLogin(enabled: true, persistPreference: false, quiet: true)
            launchAtLoginNeedsApproval = SMAppService.mainApp.status == .requiresApproval
            return
        }

        if !settings.launchAtLogin, osEnabled {
            applyLaunchAtLogin(enabled: false, persistPreference: true, quiet: true)
        }
    }

    private func applyLaunchAtLogin(enabled: Bool, persistPreference: Bool, quiet: Bool = false) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled {
                    try service.register()
                }
            } else if service.status != .notRegistered {
                try service.unregister()
            }

            launchAtLoginNeedsApproval = service.status == .requiresApproval
            if persistPreference {
                persistLaunchAtLoginPreference(enabled)
            }

            if quiet { return }

            if enabled, service.status == .requiresApproval {
                statusMessage = "macOS needs approval for launch at login in System Settings → Login Items."
            } else {
                statusMessage = enabled ? "Launch at login enabled" : "Launch at login disabled"
            }
        } catch {
            let actuallyEnabled = SMAppService.mainApp.status == .enabled
            launchAtLoginNeedsApproval = SMAppService.mainApp.status == .requiresApproval
            if persistPreference {
                persistLaunchAtLoginPreference(actuallyEnabled)
            }
            appendActivity(kind: .error, message: "Launch at login failed", detail: error.localizedDescription)
            if quiet { return }
            if SMAppService.mainApp.status == .requiresApproval {
                statusMessage = "macOS needs approval for launch at login in System Settings → Login Items."
            } else {
                statusMessage = "Could not update launch at login: \(error.localizedDescription). Preference was left matching the system."
            }
        }
    }

    private func persistLaunchAtLoginPreference(_ enabled: Bool) {
        let newSettings = settings.updating(launchAtLogin: enabled)
        do {
            try appSettingsStore.save(newSettings)
            settings = newSettings
        } catch {
            appendActivity(kind: .error, message: "Settings save failed", detail: error.localizedDescription)
            statusMessage = "Could not save settings: \(error.localizedDescription)"
        }
    }

    private static func nilIfBlank(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
        case "virtualdj":
            return VirtualDJHistoryParser()
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


extension AppModel {
    func previewApplyCaptureState(_ state: CaptureUIState) { captureState = state }

    func candidateTracklists(for archive: ArchiveMetadata) -> [ImportedTracklist] {
        let matchable = allImportedTracklists.filter(\.kind.isMatchableToRecording)
        if LibrarySessionMatcher.hardwareCaptureAppIDs.contains(archive.sourceAppID) {
            return matchable.filter { LibrarySessionMatcher.hardwareRelatedTracklistAppIDs.contains($0.appID) }
        }
        return matchable.filter { $0.appID == archive.sourceAppID }
    }

    func refreshAudioInputs() {
        let devices = AudioInputDeviceCatalog.listInputs()
        var next = captureState
        next.devices = devices
        if next.selectedDeviceID == nil {
            next.selectedDeviceID = settings.lastCaptureDeviceID ?? AudioInputDeviceCatalog.preferredDefault(from: devices)?.id
        } else if !devices.contains(where: { $0.id == next.selectedDeviceID }) {
            next.selectedDeviceID = AudioInputDeviceCatalog.preferredDefault(from: devices)?.id
        }
        if case .failed = next.phase {
            next.phase = devices.isEmpty ? .failed("No audio input devices are available.") : .armed
        } else if next.phase == .idle {
            next.phase = devices.isEmpty ? .idle : .armed
        }
        next.statusMessage = devices.isEmpty ? "Connect a DJM or other audio input, then refresh devices." : "Choose an input device, then start Capture."
        captureState = next
    }

    func selectCaptureDevice(_ deviceID: String) {
        var next = captureState
        next.selectedDeviceID = deviceID
        captureState = next
        let newSettings = settings.updating(lastCaptureDeviceID: .some(deviceID))
        do { try appSettingsStore.save(newSettings); settings = newSettings } catch {}
    }

    func startCapture() {
        refreshAudioInputs()
        guard let device = captureState.selectedDevice else {
            var next = captureState
            next.phase = .failed("Choose an audio input device before starting Capture.")
            next.statusMessage = "Choose an audio input device before starting Capture."
            captureState = next
            return
        }
        Task {
            var requesting = captureState
            requesting.phase = .requestingPermission
            requesting.statusMessage = "Requesting microphone access…"
            captureState = requesting
            if !CaptureService.microphonePermissionGranted() {
                let granted = await CaptureService.requestMicrophonePermission()
                guard granted else {
                    var denied = captureState
                    denied.phase = .failed("Microphone access is denied. DJMemory cannot Capture without it.")
                    denied.statusMessage = "Microphone access is denied. Open System Settings to allow DJMemory."
                    captureState = denied
                    statusMessage = "Microphone access is denied"
                    return
                }
            }
            do {
                try captureService.start(device: device)
                var recording = captureState
                recording.phase = .recording
                recording.inputLevel = 0
                recording.statusMessage = "Capturing from \(device.name)…"
                captureState = recording
                statusMessage = "Capture started"
                captureMeterTask?.cancel()
                captureMeterTask = Task { [weak self] in
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        await MainActor.run {
                            guard let self, self.captureState.isRecording else { return }
                            var next = self.captureState
                            next.inputLevel = self.captureService.currentInputLevel()
                            self.captureState = next
                        }
                    }
                }
            } catch let error as CaptureServiceError {
                applyCaptureFailure(error)
            } catch {
                var failed = captureState
                failed.phase = .failed(error.localizedDescription)
                failed.statusMessage = error.localizedDescription
                captureState = failed
            }
        }
    }

    func stopCapture() {
        captureMeterTask?.cancel(); captureMeterTask = nil
        var saving = captureState
        saving.phase = .saving
        saving.statusMessage = "Saving capture into your archive…"
        captureState = saving
        do {
            let result = try captureService.stop()
            let session = try archiveService().ingestCapture(stagingURL: result.stagingURL, deviceID: result.deviceID, deviceName: result.deviceName, startedAt: result.startedAt, endedAt: result.endedAt)
            refresh()
            var done = captureState
            done.phase = .armed
            done.inputLevel = 0
            done.lastArchivedSessionID = session.id
            done.statusMessage = "Capture saved. Import a tracklist from Set Detail when you have an export."
            captureState = done
            notificationService.notifyArchiveSaved(count: 1)
            statusMessage = "Capture saved"
        } catch let error as CaptureServiceError {
            applyCaptureFailure(error)
        } catch {
            var failed = captureState
            failed.phase = .failed(error.localizedDescription)
            failed.statusMessage = error.localizedDescription
            captureState = failed
            statusMessage = "Could not save capture: \(error.localizedDescription)"
        }
    }

    func openMicrophonePrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    func setCloudSyncEnabled(_ enabled: Bool) {
        let newSettings = settings.updating(cloudSyncEnabled: enabled, cloudArchiveBackupEnabled: enabled ? settings.cloudArchiveBackupEnabled : false)
        try? appSettingsStore.save(newSettings)
        settings = newSettings
        statusMessage = enabled ? "Cloud sync is on. Archive backup stays off until you enable it." : "Cloud sync is off. Everything stays on this Mac."
    }

    func setCloudArchiveBackupEnabled(_ enabled: Bool) {
        guard settings.cloudSyncEnabled || !enabled else {
            statusMessage = "Turn on cloud sync before enabling archive backup."
            return
        }
        let newSettings = settings.updating(cloudArchiveBackupEnabled: enabled)
        try? appSettingsStore.save(newSettings)
        settings = newSettings
        statusMessage = enabled ? "Archive backup is opted in. DJMemory will never upload audio automatically." : "Archive backup is off."
    }

    func exportPublishPack(sessionID: UUID) {
        guard let summary = librarySummaries.first(where: { $0.id == sessionID }) else {
            statusMessage = "Select an archived set before exporting a publish pack."
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Export"
        panel.message = "Choose a folder for the local publish pack. Nothing is uploaded."
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        do {
            let packURL = try PublishExportService().exportPack(archive: summary.archive, tracklist: summary.matchedTracklist, destinationDirectory: destination)
            NSWorkspace.shared.activateFileViewerSelecting([packURL])
            statusMessage = "Publish pack exported"
        } catch {
            statusMessage = "Could not export publish pack: \(error.localizedDescription)"
        }
    }

    func runVirtualDJNetworkCommand(_ command: VirtualDJNetworkCommand) {
        guard !isCheckingVirtualDJNetwork else { return }
        isCheckingVirtualDJNetwork = true
        Task {
            let result = await VirtualDJNetworkClient().run(command: command)
            await MainActor.run {
                virtualDJNetworkCommandResult = result
                isCheckingVirtualDJNetwork = false
                statusMessage = result.reachable ? "VirtualDJ Network Control command succeeded" : "VirtualDJ Network Control command failed"
            }
        }
    }

    private func applyCaptureFailure(_ error: CaptureServiceError) {
        let message: String
        switch error {
        case .permissionDenied: message = "Microphone access is denied. Open System Settings to allow DJMemory."
        case .deviceMissing: message = "The selected audio input is missing. Refresh devices and try again."
        case .diskFull: message = "This Mac is out of disk space. Free space, then Capture again."
        case .engineFailed(let detail): message = "Capture engine failed: \(detail)"
        case .alreadyRecording: message = "Capture is already running."
        case .notRecording: message = "Capture is not running."
        }
        var failed = captureState
        failed.phase = .failed(message)
        failed.inputLevel = 0
        failed.statusMessage = message
        captureState = failed
        statusMessage = message
    }
}
