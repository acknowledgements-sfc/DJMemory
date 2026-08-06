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
                model.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Text(model.archiveRoot.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 260, alignment: .leading)
        }
        .padding(12)
    }
}
