import DJMemoryCore
import SwiftUI

struct CompanionLibraryView: View {
    @Bindable var model: CompanionModel
    @State private var selectedSessionID: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if model.sessions.isEmpty {
                    ContentUnavailableView {
                        Label("No sets archived yet", systemImage: "rectangle.stack")
                    } description: {
                        Text("Import a djay recording from Files, or use Capture. Serato and other desktop apps stay on the Mac.")
                    } actions: {
                        Button("Import") {
                            model.selectedRoute = .importSets
                        }
                        .accessibilityIdentifier("ipad.library.emptyImport")
                    }
                } else {
                    List(selection: $selectedSessionID) {
                        ForEach(model.sessions) { session in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.originalFilename)
                                    .font(.body.weight(.medium))
                                Text("\(MobileDJSoftware.displayName(for: session.sourceAppID)) · \(session.detectedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .tag(Optional(session.sessionID))
                            .accessibilityIdentifier("ipad.library.row.\(session.sessionID.uuidString)")
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        model.refresh()
                    }
                    .accessibilityIdentifier("ipad.library.refresh")
                }
            }
            .navigationDestination(item: $selectedSessionID) { sessionID in
                CompanionSetDetailView(model: model, sessionID: sessionID)
            }
        }
    }
}

#Preview("Empty") {
    CompanionLibraryView(model: CompanionModel())
}
