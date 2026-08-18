import Foundation

#if os(macOS)
/// Headless App audio Capture probe (shared by `djmemory` CLI and `DJMemoryApp --app-audio-probe`).
public enum AppAudioProbeRunner {
    public static func run(softwareID: String?, seconds: Int) {
        let seconds = max(1, seconds)
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            defer { semaphore.signal() }
            print("preflight: \(AppAudioCaptureService.screenCapturePermissionGranted())")
            if !AppAudioCaptureService.screenCapturePermissionGranted() {
                print("requesting Screen & System Audio Recording…")
                _ = AppAudioCaptureService.requestScreenCapturePermission()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                print("preflight after request: \(AppAudioCaptureService.screenCapturePermissionGranted())")
            }

            let service = AppAudioCaptureService()
            do {
                let apps = try await service.listShareableDJApps()
                if apps.isEmpty {
                    print("targets: (none) — open a DJ app, or grant Screen & System Audio Recording.")
                    return
                }
                for app in apps {
                    print("target: \(app.software.displayName) (\(app.matchedBundleIdentifier)) id=\(app.software.id)")
                }

                let chosen: MatchedDJApp
                if let softwareID, let match = apps.first(where: { $0.software.id == softwareID }) {
                    chosen = match
                } else if let softwareID {
                    print("ERROR: requested app '\(softwareID)' is not among shareable targets.")
                    return
                } else {
                    chosen = apps.first(where: { $0.software.id == "serato" }) ?? apps[0]
                }

                print("monitoring: \(chosen.software.displayName) id=\(chosen.software.id)")
                let devices = AudioInputDeviceCatalog.listInputs()
                let runningIDs = Set(apps.map(\.software.id))
                try await service.startMonitoring(
                    bundleIdentifier: chosen.matchedBundleIdentifier,
                    displayName: chosen.software.displayName,
                    softwareID: chosen.software.id,
                    inputDevices: devices,
                    runningSoftwareIDs: runningIDs
                )
                print("backend: \(service.activeBackendKind.displayName)")
                if let device = service.activeVirtualDevice {
                    print(
                        "device: \(device.name) uid=\(device.id) transport=\(device.transportType.archiveLabel)"
                    )
                }
                var peak: Float = 0
                let ticks = max(1, seconds * 5)
                for i in 0..<ticks {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    let level = service.currentInputLevel()
                    peak = max(peak, level)
                    if i % 5 == 0 {
                        print(String(format: "t=%.1fs level=%.4f", Double(i) * 0.2, level))
                    }
                }
                print(String(format: "peak: %.4f", peak))
                if peak > 0.01 {
                    let recordingStartedAt = Date()
                    try service.beginRecordingFile()
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    if let result = try service.endRecordingFile(discard: false) {
                        let size = (try? FileManager.default.attributesOfItem(atPath: result.stagingURL.path)[.size] as? NSNumber)?.intValue ?? 0
                        print("staging: \(result.stagingURL.path) bytes=\(size)")
                        let session = try ArchiveService().ingestCapture(
                            stagingURL: result.stagingURL,
                            deviceID: result.deviceID,
                            deviceName: result.deviceName,
                            startedAt: recordingStartedAt,
                            sourceAppID: chosen.software.id,
                            captureRoute: result.captureRoute ?? .appAudio,
                            captureBackend: result.captureBackend ?? service.activeBackendKind.archiveBackend,
                            captureDeviceTransport: result.deviceTransport?.archiveLabel
                        )
                        guard let archiveURL = session.archiveURL else {
                            print("ERROR: archive session missing archive URL \(session.id.uuidString)")
                            return
                        }
                        print("archive: \(archiveURL.path)")
                        print("metadata: \(ArchiveService().metadataURL(for: archiveURL).path)")
                        let archivedIDs = try SessionLibrary().archivedMetadata().map(\.id)
                        if archivedIDs.contains(session.id) {
                            print("library: found \(session.id.uuidString)")
                        } else {
                            print("library: missing \(session.id.uuidString)")
                        }
                        print("PASS meter+archive \(chosen.software.id)")
                    }
                } else {
                    print("SILENT_METER — play audio through system output, or use Input device Capture if the mix is hardware-only.")
                    print("ARMED_OK \(chosen.software.id) — shareable + monitoring started; meter not verified.")
                }
                await service.stopMonitoring()
                print("DONE")
            } catch {
                print("ERROR: \(error)")
            }
        }

        semaphore.wait()
    }

    /// Parses `app-audio-probe` / `--app-audio-probe` trailing args: optional seconds and/or software id.
    public static func parseArgs(_ args: [String]) -> (softwareID: String?, seconds: Int) {
        var softwareID: String?
        var seconds = 8
        for arg in args {
            if let value = Int(arg), value > 0 {
                seconds = value
            } else if !arg.hasPrefix("-") {
                softwareID = arg
            }
        }
        return (softwareID, seconds)
    }
}
#endif
