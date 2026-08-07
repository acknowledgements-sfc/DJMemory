import SwiftUI
import DJMemoryCore

struct ScanResultsView: View {
    let results: [FolderScanResult]

    var body: some View {
        if !results.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Latest Scan")
                    .font(.headline)

                ForEach(results, id: \.folderURL) { result in
                    HStack(spacing: 10) {
                        Image(systemName: scanResultSymbol(for: result))
                            .foregroundStyle(scanResultTint(for: result))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(result.folderURL.path)
                                .font(.caption.monospaced())
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(result.folderURL.path)

                            if let errorDescription = result.errorDescription {
                                Text(errorDescription)
                                    .foregroundStyle(.secondary)
                                    .help(errorDescription)
                            } else if !result.pendingRecordingURLs.isEmpty {
                                Text("\(result.pendingRecordingURLs.count) active recording\(result.pendingRecordingURLs.count == 1 ? "" : "s") waiting to finish")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(result.archivedSessions.count) new recording\(result.archivedSessions.count == 1 ? "" : "s") archived")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(DJToken.card, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
                    .overlay(
                        RoundedRectangle(cornerRadius: DJToken.Radius.control)
                            .stroke(DJToken.border, lineWidth: 1)
                    )
                    .help(scanResultHelp(for: result))
                }
            }
        }
    }

    private func scanResultHelp(for result: FolderScanResult) -> String {
        if let errorDescription = result.errorDescription {
            return "\(result.folderURL.path)\n\(errorDescription)"
        }

        if !result.pendingRecordingURLs.isEmpty {
            let names = result.pendingRecordingURLs
                .map(\.lastPathComponent)
                .joined(separator: "\n")
            return "\(result.folderURL.path)\nWaiting for recording to finish:\n\(names)"
        }

        return "\(result.folderURL.path)\n\(result.archivedSessions.count) new recording\(result.archivedSessions.count == 1 ? "" : "s") archived"
    }

    private func scanResultSymbol(for result: FolderScanResult) -> String {
        if result.errorDescription != nil { return "exclamationmark.triangle" }
        if !result.pendingRecordingURLs.isEmpty { return "record.circle.fill" }
        return "checkmark.circle"
    }

    private func scanResultTint(for result: FolderScanResult) -> Color {
        if result.errorDescription != nil { return DJToken.warn }
        if !result.pendingRecordingURLs.isEmpty { return DJToken.danger }
        return DJToken.ok
    }
}
