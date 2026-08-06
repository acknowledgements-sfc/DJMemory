import Foundation
import SetCatcherCore

let arguments = CommandLine.arguments.dropFirst()

guard arguments.first == "probe" else {
    print("Usage: setcatcher probe")
    exit(0)
}

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
