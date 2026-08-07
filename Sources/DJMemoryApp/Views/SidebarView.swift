import SwiftUI
import DJMemoryCore

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isAddAppPresented = false
    var initiallyPresentAddApp: Bool = false

    var body: some View {
        List(selection: $model.selectedRoute) {
            Section("DJMemory") {
                Label("Home", systemImage: "house")
                    .tag(Route.home)
                    .accessibilityIdentifier("sidebar.home")
                Label("Protection", systemImage: model.protectionSymbolName)
                    .tag(Route.protection)
                    .accessibilityIdentifier("sidebar.protection")
                Label("Library", systemImage: "music.note.list")
                    .tag(Route.library)
                    .accessibilityIdentifier("sidebar.library")
                Label("Activity", systemImage: "clock.arrow.circlepath")
                    .tag(Route.activity)
                    .accessibilityIdentifier("sidebar.activity")
                Label("Settings", systemImage: "gearshape")
                    .tag(Route.settings)
                    .accessibilityIdentifier("sidebar.settings")
            }

            Section {
                if model.configuredProbeResults.isEmpty {
                    Text("No DJ apps set up yet. Use + to add one.")
                        .font(.system(size: DJToken.TypeSize.micro))
                        .foregroundStyle(DJToken.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(model.configuredProbeResults, id: \.software.id) { result in
                        configuredAppRow(result)
                            .tag(Route.app(result.software.id))
                            .accessibilityIdentifier("sidebar.app.\(result.software.id)")
                    }
                }
            } header: {
                HStack(spacing: 4) {
                    Text("DJ Apps")
                    Spacer(minLength: 0)
                    Button {
                        isAddAppPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(isAddAppPresented ? DJToken.foreground : DJToken.mutedForeground)
                    .background(
                        isAddAppPresented ? DJToken.secondary : Color.clear,
                        in: RoundedRectangle(cornerRadius: DJToken.Radius.badge)
                    )
                    .help("Add a DJ app")
                    .accessibilityLabel("Add a DJ app")
                    .accessibilityIdentifier("sidebar.addApp")
                    .popover(isPresented: $isAddAppPresented, arrowEdge: .bottom) {
                        AddAppPickerView(
                            options: model.unconfiguredProbeResults,
                            onPick: { appID in
                                model.selectedRoute = .app(appID)
                                isAddAppPresented = false
                            }
                        )
                        .frame(width: 280)
                    }
                }
            }
        }
        .navigationTitle("DJMemory")
        .background(DJToken.background)
        .onAppear {
            if initiallyPresentAddApp {
                isAddAppPresented = true
            }
        }
    }

    @ViewBuilder
    private func configuredAppRow(_ result: SoftwareProbeResult) -> some View {
        let unreachable = model.isConfiguredRecordingsFolderUnreachable(appID: result.software.id)
        let tone: StatusTone = {
            if unreachable {
                return .danger
            }
            if model.isScanning {
                return .info
            }
            return .ok
        }()

        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: DJToken.Radius.swatch)
                .fill(DJToken.accent(forAppID: result.software.id))
                .frame(width: 3, height: 14)

            Text(result.software.displayName)
                .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                .lineLimit(1)

            Spacer(minLength: 0)

            StatusDot(tone: tone, pulse: model.isScanning && !unreachable)
        }
    }
}

// MARK: - Previews (§4.10 sidebar sources matrix)

#Preview("Sidebar sources — none configured / light") {
    sidebarPreview(configured: [], unreachable: [])
        .preferredColorScheme(.light)
}

#Preview("Sidebar sources — none configured / dark") {
    sidebarPreview(configured: [], unreachable: [])
        .preferredColorScheme(.dark)
}

#Preview("Sidebar sources — some configured / light") {
    sidebarPreview(configured: ["serato", "rekordbox"], unreachable: [])
        .preferredColorScheme(.light)
}

#Preview("Sidebar sources — some configured / dark") {
    sidebarPreview(configured: ["serato", "rekordbox"], unreachable: [])
        .preferredColorScheme(.dark)
}

#Preview("Sidebar sources — one unreachable / light") {
    sidebarPreview(configured: ["serato"], unreachable: ["traktor"])
        .preferredColorScheme(.light)
}

#Preview("Sidebar sources — one unreachable / dark") {
    sidebarPreview(configured: ["serato"], unreachable: ["traktor"])
        .preferredColorScheme(.dark)
}

@MainActor
private func sidebarPreview(configured: [String], unreachable: [String]) -> some View {
    let model = AppModel()
    model.previewApplyConfiguredRecordingsFolders(
        reachableAppIDs: configured,
        unreachableAppIDs: unreachable
    )

    return NavigationSplitView {
        SidebarView()
            .environmentObject(model)
    } detail: {
        Text("Detail")
            .foregroundStyle(DJToken.mutedForeground)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DJToken.content)
    }
    .frame(width: 720, height: 480)
}
