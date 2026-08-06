import Foundation

public struct PathResolver: Sendable {
    public init() {}

    public func expandedURL(for path: String) -> URL {
        let expanded = (path as NSString).expandingTildeInPath
        return URL(fileURLWithPath: expanded)
    }

    public func existingURLs(from paths: [String]) -> [URL] {
        paths
            .map(expandedURL(for:))
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
