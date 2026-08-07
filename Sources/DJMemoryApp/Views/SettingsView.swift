import SwiftUI
import DJMemoryCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    private let intervalOptions = [30, 60, 120, 300]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Settings")
                .font(.system(size: DJToken.TypeSize.title, weight: .semibold))
                .foregroundStyle(DJToken.foreground)

            scanningPanel
            archivePanel
            currentStatePanel
            accountPanel
        }
    }

    private var scanningPanel: some View {
        Panel(title: "Scanning", padding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                settingsToggle(
                    title: "Automatic scanning",
                    explanation: "When on, DJMemory scans configured recording folders while the app is open.",
                    isOn: Binding(
                        get: { model.settings.automaticScanningEnabled },
                        set: { model.updateAutomaticScanning(enabled: $0) }
                    ),
                    id: "settings.automaticScanning"
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scan interval")
                        .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                    Text(intervalExplanation)
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                    Picker(
                        "Scan interval",
                        selection: Binding(
                            get: { model.settings.scanIntervalSeconds },
                            set: { model.updateScanInterval(seconds: $0) }
                        )
                    ) {
                        ForEach(intervalOptions, id: \.self) { seconds in
                            Text(intervalLabel(seconds)).tag(seconds)
                        }
                    }
                    .disabled(!model.settings.automaticScanningEnabled)
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.scanInterval")
                }

                settingsToggle(
                    title: "Verify each copy",
                    explanation: "After archiving, confirm the protected copy matches the source file size.",
                    isOn: Binding(
                        get: { model.settings.verifyCopies },
                        set: { model.updateVerifyCopies(enabled: $0) }
                    ),
                    id: "settings.verifyCopies"
                )

                settingsToggle(
                    title: "Notify after archiving",
                    explanation: "Show a local notification when a recording is safely copied.",
                    isOn: Binding(
                        get: { model.settings.notifyAfterArchiving },
                        set: { model.updateNotifyAfterArchiving(enabled: $0) }
                    ),
                    id: "settings.notifyAfterArchiving"
                )

                settingsToggle(
                    title: "Launch at login",
                    explanation: "Open DJMemory when you sign in to this Mac.",
                    isOn: Binding(
                        get: { model.settings.launchAtLogin },
                        set: { model.updateLaunchAtLogin(enabled: $0) }
                    ),
                    id: "settings.launchAtLogin"
                )
            }
        }
    }

    private var archivePanel: some View {
        Panel(title: "Archive", padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    PathChip(path: model.archiveRoot.path)
                    Button("Change") { model.chooseArchiveFolder() }
                        .buttonStyle(DJSecondaryButtonStyle())
                        .accessibilityIdentifier("settings.archive.choose")
                    Button("Open") { model.openArchiveFolder() }
                        .buttonStyle(DJGhostButtonStyle())
                        .accessibilityIdentifier("settings.archive.open")
                    Button("Reset") { model.resetArchiveFolder() }
                        .buttonStyle(DJGhostButtonStyle())
                        .disabled(model.settings.archiveRootPath == nil)
                        .accessibilityIdentifier("settings.archive.reset")
                }

                TextField(
                    "Archive naming template",
                    text: Binding(
                        get: { model.settings.archiveNamingTemplate },
                        set: { model.updateArchiveNamingTemplate($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .help("Available tokens: {date}, {time}, {app}, {source}.")
                .accessibilityIdentifier("settings.archiveNamingTemplate")

                KeyValueRow(key: "Example", value: exampleArchiveName(), mono: true, showsDivider: false)

                Text("Source recordings stay where they are. DJMemory writes protected copies and metadata sidecars here.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.mutedForeground)
            }
        }
    }

    private var currentStatePanel: some View {
        Panel(title: "Current State", padding: 0) {
            KeyValueRow(key: "Archive folder", value: model.archiveRoot.path, mono: true)
            KeyValueRow(key: "Protected sources", value: "\(model.protectedAdapterCount)")
            KeyValueRow(key: "Archived sets", value: "\(model.sessions.count)")
            KeyValueRow(key: "Imported tracklists", value: "\(model.allImportedTracklists.count)")
            KeyValueRow(key: "Archive size on disk", value: ByteCountFormatter.string(fromByteCount: archiveSize, countStyle: .file))
            KeyValueRow(key: "Version", value: appVersion, showsDivider: false)
        }
    }

    private var accountPanel: some View {
        Panel(title: "Account", padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Local protection never depends on an account.")
                    .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                Text("Audio files are never uploaded by default.")
                    .font(.system(size: DJToken.TypeSize.body))
                    .foregroundStyle(DJToken.mutedForeground)
                Text("Full tracklists stay on this Mac unless you explicitly export them.")
                    .font(.system(size: DJToken.TypeSize.body))
                    .foregroundStyle(DJToken.mutedForeground)
                Text("Diagnostics exports contain metadata only — paths, timings, counts, and error strings.")
                    .font(.system(size: DJToken.TypeSize.body))
                    .foregroundStyle(DJToken.mutedForeground)

                Button {
                    model.showOnboardingAgain()
                } label: {
                    Label("Show First-Run Setup", systemImage: "sparkles.rectangle.stack")
                }
                .buttonStyle(DJSecondaryButtonStyle())
                .padding(.top, 6)
                .accessibilityIdentifier("settings.showOnboarding")
            }
        }
    }

    private func settingsToggle(title: String, explanation: String, isOn: Binding<Bool>, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(title, isOn: isOn)
                .accessibilityIdentifier(id)
            Text(explanation)
                .font(.system(size: DJToken.TypeSize.secondary))
                .foregroundStyle(DJToken.mutedForeground)
        }
    }

    private var intervalExplanation: String {
        switch model.settings.scanIntervalSeconds {
        case 30: return "Check watched folders every 30 seconds while the app is open."
        case 60: return "Check watched folders once a minute while the app is open."
        case 120: return "Check watched folders every 2 minutes while the app is open."
        case 300: return "Check watched folders every 5 minutes while the app is open."
        default: return "How often DJMemory checks configured recording folders while automatic scanning is on."
        }
    }

    private var archiveSize: Int64 {
        model.sessions.reduce(0) { $0 + $1.fileSize }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private func intervalLabel(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m"
    }

    private func exampleArchiveName() -> String {
        let template = model.settings.archiveNamingTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? AppSettings.defaultArchiveNamingTemplate
            : model.settings.archiveNamingTemplate
        return template
            .replacingOccurrences(of: "{date}", with: "2026-08-06")
            .replacingOccurrences(of: "{time}", with: "2230")
            .replacingOccurrences(of: "{app}", with: "Serato DJ Pro")
            .replacingOccurrences(of: "{source}", with: "Club Recording")
            + ".wav"
    }
}
