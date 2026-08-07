import SwiftUI
import DJMemoryCore

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DashboardView()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.scanNow()
                } label: {
                    Label(model.isScanning ? "Scanning" : "Rescan 24h", systemImage: "waveform.badge.magnifyingglass")
                }
                .disabled(model.isScanning)
                .help("Scan configured recording folders for completed audio files from the last 24 hours.")
                .accessibilityIdentifier("toolbar.scanNow")
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    model.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh app detection, folder access, imports, archive metadata, and activity.")
                .accessibilityIdentifier("toolbar.refresh")
            }
        }
        .sheet(
            isPresented: Binding(
                get: { !model.settings.hasCompletedOnboarding },
                set: { isPresented in
                    if !isPresented {
                        model.completeOnboarding()
                    }
                }
            )
        ) {
            OnboardingView()
                .environmentObject(model)
        }
    }
}
