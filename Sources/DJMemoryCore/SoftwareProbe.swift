import AppKit
import Foundation

public struct SoftwareProbeResult: Codable, Equatable, Sendable {
    public let software: DJSoftware
    public let installedApplicationURLs: [URL]
    public let runningApplicationBundleIdentifiers: [String]
    public let existingRecordingURLs: [URL]
    public let existingHistoryURLs: [URL]

    public var status: String {
        if !runningApplicationBundleIdentifiers.isEmpty {
            return "running"
        }

        if !installedApplicationURLs.isEmpty {
            return "installed"
        }

        if !existingRecordingURLs.isEmpty || !existingHistoryURLs.isEmpty {
            return "folders-found"
        }

        return "not-found"
    }

    public var isRunning: Bool {
        !runningApplicationBundleIdentifiers.isEmpty
    }
}

public struct SoftwareProbe {
    private let workspace: NSWorkspace
    private let resolver: PathResolver

    public init(workspace: NSWorkspace = .shared, resolver: PathResolver = PathResolver()) {
        self.workspace = workspace
        self.resolver = resolver
    }

    public func probe(_ software: DJSoftware) -> SoftwareProbeResult {
        let appURLs = software.bundleIdentifiers.compactMap { workspace.urlForApplication(withBundleIdentifier: $0) }
        let runningBundleIDs = Set(workspace.runningApplications.compactMap(\.bundleIdentifier))
        let runningMatches = software.bundleIdentifiers.filter { runningBundleIDs.contains($0) }

        return SoftwareProbeResult(
            software: software,
            installedApplicationURLs: appURLs,
            runningApplicationBundleIdentifiers: runningMatches,
            existingRecordingURLs: resolver.existingURLs(from: software.defaultRecordingPaths),
            existingHistoryURLs: resolver.existingURLs(from: software.defaultHistoryPaths)
        )
    }

    public func probeAll() -> [SoftwareProbeResult] {
        SupportedDJSoftware.all.map(probe(_:))
    }
}
