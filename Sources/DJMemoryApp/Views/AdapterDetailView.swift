import SwiftUI
import DJMemoryCore

struct AdapterDetailView: View {
    @EnvironmentObject private var model: AppModel

    var selectedResult: SoftwareProbeResult? {
        if let appID = model.selectedAppID {
            return model.probeResults.first { $0.software.id == appID } ?? model.probeResults.first
        }
        return model.probeResults.first
    }

    var body: some View {
        if let result = selectedResult {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(result.software.displayName)
                        .font(.system(size: DJToken.TypeSize.title, weight: .semibold))
                    SupportBadge(status: result.software.supportStatus)
                    Spacer()
                }

                if model.isConfiguredRecordingsFolderUnreachable(appID: result.software.id) {
                    Panel(title: "Folder Unavailable", tone: .danger, padding: 12) {
                        HStack {
                            Text("A saved folder is unavailable, so new sets are not being archived. Everything already in your archive is safe.")
                                .font(.system(size: DJToken.TypeSize.body))
                                .foregroundStyle(DJToken.mutedForeground)
                            Spacer()
                            Button("Start Recovery") {
                                model.selectedRoute = .recovery(result.software.id)
                            }
                            .buttonStyle(DJPrimaryButtonStyle())
                            .accessibilityIdentifier("setup.\(result.software.id).startRecovery")
                        }
                    }
                }

                FolderQuickActionsView(result: result)

                StatusGrid(
                    result: result,
                    setupState: model.setupState(for: result),
                    recordingFolders: model.recordingFolders(for: result.software.id),
                    historyFolders: model.historyFolders(for: result.software.id)
                )

                FolderSetupView(result: result)

                HStack(alignment: .top, spacing: 12) {
                    ScanResultsView(results: model.scanResults(for: result.software.id))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Panel(title: "Privacy", padding: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Audio files stay on this Mac", systemImage: "checkmark.circle.fill")
                            Label("Full tracklists are never uploaded by default", systemImage: "checkmark.circle.fill")
                            Label("Source recordings are copied, never moved", systemImage: "checkmark.circle.fill")
                        }
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                    }
                    .frame(width: 280)
                }

                HistoryImportView(result: result)

                if result.software.id == "virtualdj" {
                    VirtualDJNetworkControlView()
                }

                Panel(title: "Setup", padding: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(setupSteps(for: result).enumerated()), id: \.offset) { index, step in
                            Text("\(index + 1). \(step)")
                                .font(.system(size: DJToken.TypeSize.body))
                                .foregroundStyle(DJToken.foreground)
                        }

                        if result.software.supportStatus != .supported {
                            Text("\(result.software.supportStatus.displayName): \(result.software.notes)")
                                .font(.system(size: DJToken.TypeSize.secondary))
                                .foregroundStyle(DJToken.warn)
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    private func setupSteps(for result: SoftwareProbeResult) -> [String] {
        switch result.software.id {
        case "serato":
            return [
                "Grant access to ~/Music/_Serato_ when prompted.",
                "DJMemory watches the Recording folder.",
                "History Export files will be used for tracklists."
            ]
        case "rekordbox":
            return [
                "Choose the folder where rekordbox saves recordings.",
                "Import rekordbox XML or history exports when available.",
                "DJMemory preserves completed recordings in ~/Music/DJMemory."
            ]
        case "traktor":
            return [
                "DJMemory checks ~/Music/Traktor/Recordings when it exists.",
                "Versioned Traktor History folders are detected under Native Instruments.",
                "Import Traktor .nml history playlists for tracklists."
            ]
        case "virtualdj":
            return [
                "DJMemory checks ~/Documents/VirtualDJ when it exists.",
                "History imports support VirtualDJ text, M3U, XML, and .vdjfolder files.",
                "Deeper Network Control or plugin support remains a later decision."
            ]
        default:
            return [
                "DJMemory checks documented djay recording folders when they exist.",
                "Choose your djay recordings folder manually if the default folder is not found.",
                "History and session metadata support still needs verification."
            ]
        }
    }
}
