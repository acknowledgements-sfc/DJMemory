import Foundation
import DJMemoryCore

let arguments = Array(CommandLine.arguments.dropFirst())

switch arguments.first {
case "probe":
    runProbe()
case "archive":
    try runArchive(arguments: arguments)
case "scan":
    try runScan(arguments: arguments)
case "watch":
    try runWatch(arguments: arguments)
case "virtualdj-network":
    runVirtualDJNetworkProbe(arguments: arguments)
default:
    printUsage()
}

private func printUsage() {
    print("""
    Usage:
      djmemory probe
      djmemory archive <file> [appID]
      djmemory scan <folder> [appID]
      djmemory watch <folder> [appID]
      djmemory virtualdj-network [endpointURL]
    """)
}

private func runProbe() {
    let probe = SoftwareProbe()
    let results = probe.probeAll()

    for result in results {
        print("\(result.software.displayName): \(result.status)")

        for url in result.installedApplicationURLs {
            print("  app: \(url.path)")
        }

        for url in result.existingRecordingURLs {
            print("  recordings: \(url.path)")
        }

        for url in result.existingHistoryURLs {
            print("  history: \(url.path)")
        }
    }
}

private func runArchive(arguments: [String]) throws {
    guard arguments.count >= 2 else {
        printUsage()
        return
    }

    let sourceURL = URL(fileURLWithPath: (arguments[1] as NSString).expandingTildeInPath)
    let appID = arguments.count >= 3 ? arguments[2] : "manual"
    let service = ArchiveService()
    let session = try service.archive(sourceURL: sourceURL, sourceAppID: appID)

    printArchived(session)
}

private func runScan(arguments: [String]) throws {
    guard arguments.count >= 2 else {
        printUsage()
        return
    }

    let folderURL = URL(fileURLWithPath: (arguments[1] as NSString).expandingTildeInPath, isDirectory: true)
    let appID = arguments.count >= 3 ? arguments[2] : "manual"
    let now = Date()
    let cutoff = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? .distantPast
    let stableBefore = now.addingTimeInterval(-30)
    let scanner = RecordingFolderScanner()
    let sessions = try scanner.archiveRecentStableFiles(
        in: folderURL,
        sourceAppID: appID,
        modifiedAfter: cutoff,
        stableBefore: stableBefore
    )

    if sessions.isEmpty {
        print("No recent stable audio files found.")
    } else {
        sessions.forEach(printArchived(_:))
    }
}

private func runWatch(arguments: [String]) throws {
    guard arguments.count >= 2 else {
        printUsage()
        return
    }

    let folderURL = URL(fileURLWithPath: (arguments[1] as NSString).expandingTildeInPath, isDirectory: true)
    let appID = arguments.count >= 3 ? arguments[2] : "manual"
    let stabilityChecker = FileStabilityChecker()
    let archiveService = ArchiveService()
    var snapshots: [URL: FileSnapshot] = [:]
    var archived = Set<URL>()

    print("Watching \(folderURL.path)")
    print("Archiving stable audio files to \(archiveService.archiveRoot.path)")

    while true {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) ?? .distantPast
        let candidates = try stabilityChecker.recentAudioFiles(in: folderURL, modifiedAfter: cutoff)

        for url in candidates where !archived.contains(url) {
            let snapshot = try stabilityChecker.snapshot(for: url)

            if let previousSnapshot = snapshots[url], previousSnapshot == snapshot {
                guard !archiveService.isSourceAlreadyArchived(url) else {
                    archived.insert(url)
                    continue
                }

                let session = try archiveService.archive(sourceURL: url, sourceAppID: appID)
                archived.insert(url)
                printArchived(session)
            } else {
                snapshots[url] = snapshot
            }
        }

        Thread.sleep(forTimeInterval: 30)
    }
}

private func printArchived(_ session: RecordingSession) {
    print("Archived: \(session.sourceURL.lastPathComponent)")

    if let archiveURL = session.archiveURL {
        print("  to: \(archiveURL.path)")
        print("  metadata: \(archiveURL.deletingPathExtension().appendingPathExtension("json").path)")
    }
}

private func runVirtualDJNetworkProbe(arguments: [String]) {
    let endpoint = arguments.count >= 2
        ? URL(string: arguments[1]) ?? VirtualDJNetworkProbe.defaultEndpoint
        : VirtualDJNetworkProbe.defaultEndpoint
    let semaphore = DispatchSemaphore(value: 0)

    Task {
        let result = await VirtualDJNetworkProbe().probe(endpoint: endpoint)
        print("VirtualDJ Network Control: \(result.reachable ? "reachable" : "not reachable")")
        print("  endpoint: \(result.endpoint.absoluteString)")

        if let statusCode = result.statusCode {
            print("  status: \(statusCode)")
        }

        if let errorDescription = result.errorDescription {
            print("  error: \(errorDescription)")
        }

        semaphore.signal()
    }

    semaphore.wait()
}
