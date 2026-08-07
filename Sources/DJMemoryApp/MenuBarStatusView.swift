import SwiftUI

struct MenuBarStatusView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(model.headlineStatus, systemImage: model.protectionSymbolName)
                .font(.headline)

            Text(model.statusMessage)
                .foregroundStyle(.secondary)

            Divider()

            Button {
                model.scanNow()
            } label: {
                Label(model.isScanning ? "Scanning" : "Scan Now", systemImage: "waveform.badge.magnifyingglass")
            }
            .disabled(model.isScanning)
            .help("Scan configured recording folders for new completed audio files.")

            Button {
                model.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .help("Refresh app detection, folder access, imports, archive metadata, and activity.")

            Text(model.archiveRoot.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 260, alignment: .leading)
                .help(model.archiveRoot.path)
        }
        .padding(12)
    }
}
