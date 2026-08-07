import Darwin
import Dispatch
import Foundation
import DJMemoryCore

final class FolderChangeMonitor {
    private var watchedFolders: [WatchedFolder] = []
    private var watchedPaths: Set<String> = []

    deinit {
        stop()
    }

    func start(requests: [FolderScanRequest], onChange: @escaping @Sendable () -> Void) {
        let uniqueRequests = uniqueReachableRequests(from: requests)
        let nextPaths = Set(uniqueRequests.map(\.folderURL.path))

        guard nextPaths != watchedPaths else {
            return
        }

        stop()
        watchedPaths = nextPaths

        watchedFolders = uniqueRequests.compactMap { request in
            WatchedFolder(request: request, onChange: onChange)
        }
    }

    func stop() {
        watchedFolders.forEach { $0.stop() }
        watchedFolders = []
        watchedPaths = []
    }

    private func uniqueReachableRequests(from requests: [FolderScanRequest]) -> [FolderScanRequest] {
        var seenPaths = Set<String>()

        return requests.filter { request in
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: request.folderURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue,
                  !seenPaths.contains(request.folderURL.path)
            else {
                return false
            }

            seenPaths.insert(request.folderURL.path)
            return true
        }
    }
}

private final class WatchedFolder {
    private let request: FolderScanRequest
    private let onChange: @Sendable () -> Void
    private let fileDescriptor: CInt
    private let source: DispatchSourceFileSystemObject
    private let securityScopedURL: URL?
    private let didStartAccessing: Bool

    init?(request: FolderScanRequest, onChange: @escaping @Sendable () -> Void) {
        self.request = request
        self.onChange = onChange

        var scopedURL: URL?
        var startedAccess = false
        if let bookmarkData = request.bookmarkData {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ), !isStale {
                scopedURL = url
                startedAccess = url.startAccessingSecurityScopedResource()
            }
        }

        let descriptor = open(request.folderURL.path, O_EVTONLY)
        guard descriptor >= 0 else {
            if startedAccess {
                scopedURL?.stopAccessingSecurityScopedResource()
            }
            return nil
        }

        fileDescriptor = descriptor
        securityScopedURL = scopedURL
        didStartAccessing = startedAccess

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .delete, .rename],
            queue: DispatchQueue.global(qos: .utility)
        )
        source.setEventHandler(handler: onChange)
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()
    }

    func stop() {
        source.cancel()
        if didStartAccessing {
            securityScopedURL?.stopAccessingSecurityScopedResource()
        }
    }
}
