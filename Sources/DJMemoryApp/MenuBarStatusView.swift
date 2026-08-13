import SwiftUI

struct MenuBarStatusView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(model.headlineStatus, systemImage: model.protectionSymbolName)
                .font(.headline)
                .accessibilityIdentifier("menuBar.headlineStatus")

            Text(model.statusMessage)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("menuBar.statusMessage")

            VStack(alignment: .leading, spacing: 4) {
                Label("Last scan: \(model.lastScanDisplayText)", systemImage: "checkmark.circle")
                    .accessibilityIdentifier("menuBar.lastScan")
                Label("Next scan: \(model.nextScanDisplayText)", systemImage: "clock")
                    .accessibilityIdentifier("menuBar.nextScan")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .help("Shows when DJMemory last checked folders and when automatic scanning will run again.")

            Divider()

            Button {
                model.scanNow()
            } label: {
                Label(model.isScanning ? "Scanning" : "Rescan Last 24 Hours", systemImage: "waveform.badge.magnifyingglass")
            }
            .disabled(model.isScanning)
            .help("Scan configured recording folders for completed audio files from the last 24 hours.")
            .accessibilityIdentifier("menuBar.scanNow")

            Button {
                model.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Refresh app detection, folder access, imports, archive metadata, and activity.")
            .accessibilityIdentifier("menuBar.refresh")

            Button {
                model.openArchiveFolder()
            } label: {
                Label("Open Archive", systemImage: "folder")
            }
            .help("Open the DJMemory archive folder in Finder.")
            .accessibilityIdentifier("menuBar.openArchive")

            Text(model.archiveRoot.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 260, alignment: .leading)
                .help(model.archiveRoot.path)
                .accessibilityIdentifier("menuBar.archiveRoot")
        }
        .padding(12)
    }
}
