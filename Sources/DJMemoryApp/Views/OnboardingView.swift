import SwiftUI
import DJMemoryCore

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @State private var step: Step

    enum Step: Int, CaseIterable {
        case welcome
        case djApps
        case folderAccess
        case archive
        case history
        case ready

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .djApps: return "DJ Apps"
            case .folderAccess: return "Folder Access"
            case .archive: return "Archive"
            case .history: return "History"
            case .ready: return "Ready"
            }
        }
    }

    init(startingStep: Step = .welcome) {
        _step = State(initialValue: startingStep)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepRail

            Group {
                switch step {
                case .welcome:
                    welcomeStep
                case .djApps:
                    djAppsStep
                case .folderAccess:
                    folderAccessStep
                case .archive:
                    archiveStep
                case .history:
                    historyStep
                case .ready:
                    readyStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            footer
        }
        .padding(28)
        .frame(width: 640, height: 480)
    }

    private var stepRail: some View {
        HStack(spacing: 8) {
            ForEach(Step.allCases, id: \.rawValue) { item in
                HStack(spacing: 4) {
                    Image(systemName: item.rawValue < step.rawValue ? "checkmark.circle.fill" : (item == step ? "circle.fill" : "circle"))
                        .font(.system(size: 10))
                        .foregroundStyle(item.rawValue <= step.rawValue ? DJToken.primary : DJToken.mutedForeground)
                    Text(item.title)
                        .font(.system(size: DJToken.TypeSize.micro, weight: .semibold))
                        .foregroundStyle(item == step ? DJToken.foreground : DJToken.mutedForeground)
                }
                .accessibilityIdentifier("onboarding.step.\(item.rawValue)")
                if item != .ready {
                    Rectangle()
                        .fill(DJToken.hairline)
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DJMemory keeps a backup of your recorded sets.")
                .font(.system(size: DJToken.TypeSize.title, weight: .semibold))
            Text("Choose the folders your DJ apps already record into. DJMemory copies completed recordings into your archive and leaves the originals untouched.")
                .font(.system(size: DJToken.TypeSize.body))
                .foregroundStyle(DJToken.mutedForeground)
            Text("Audio files and full tracklists stay on this Mac. Nothing is uploaded.")
                .font(.system(size: DJToken.TypeSize.secondary))
                .foregroundStyle(DJToken.mutedForeground)
        }
    }

    private var djAppsStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DJ apps found on this Mac")
                .font(.system(size: DJToken.TypeSize.body, weight: .semibold))
            ForEach(model.probeResults, id: \.software.id) { result in
                HStack {
                    RoundedRectangle(cornerRadius: DJToken.Radius.swatch)
                        .fill(DJToken.accent(forAppID: result.software.id))
                        .frame(width: 3, height: 14)
                    Text(result.software.displayName)
                    Spacer()
                    SupportBadge(status: result.software.supportStatus)
                    Text(result.installedApplicationURLs.isEmpty ? "Not installed" : "Found")
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                }
            }
            if installedCount == 0 {
                Text("Install a DJ app, or continue and choose folders manually.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.warn)
            }
        }
    }

    private var folderAccessStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Grant access to at least one recordings folder.")
                .font(.system(size: DJToken.TypeSize.body, weight: .semibold))
            ForEach(model.probeResults.prefix(5), id: \.software.id) { result in
                HStack {
                    Text(result.software.displayName)
                    Spacer()
                    if model.hasConfiguredRecordingsFolder(appID: result.software.id) {
                        Badge(title: "Granted", tone: .ok)
                    } else {
                        Button("Choose Folder") {
                            model.chooseFolder(appID: result.software.id, kind: .recordings)
                        }
                        .buttonStyle(DJSecondaryButtonStyle())
                        .accessibilityIdentifier("onboarding.folder.\(result.software.id)")
                    }
                }
            }
        }
    }

    private var archiveStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Archive location")
                .font(.system(size: DJToken.TypeSize.body, weight: .semibold))
            PathChip(path: model.archiveRoot.path)
            Text("Source recordings stay where they are. DJMemory writes protected copies here.")
                .font(.system(size: DJToken.TypeSize.secondary))
                .foregroundStyle(DJToken.mutedForeground)
            Button("Change Archive Folder") {
                model.chooseArchiveFolder()
            }
            .buttonStyle(DJSecondaryButtonStyle())
            .accessibilityIdentifier("onboarding.reviewArchive")
        }
    }

    private var historyStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Track history is optional")
                .font(.system(size: DJToken.TypeSize.body, weight: .semibold))
            Text("You can import set histories later from each app’s setup screen. Skipping this step is safe.")
                .font(.system(size: DJToken.TypeSize.body))
                .foregroundStyle(DJToken.mutedForeground)
        }
    }

    private var readyStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You’re ready")
                .font(.system(size: DJToken.TypeSize.title, weight: .semibold))
            Text("DJMemory will watch granted folders and copy completed recordings into your archive.")
                .font(.system(size: DJToken.TypeSize.body))
                .foregroundStyle(DJToken.mutedForeground)
            MetricTile(label: "Protected sources", value: "\(model.protectedAdapterCount)", tone: model.protectedAdapterCount > 0 ? .ok : .warn)
        }
    }

    private var footer: some View {
        HStack {
            if step != .welcome {
                Button("Back") {
                    if let previous = Step(rawValue: step.rawValue - 1) {
                        step = previous
                    }
                }
                .buttonStyle(DJGhostButtonStyle())
                .accessibilityIdentifier("onboarding.back")
            }

            Button("Skip setup") {
                model.completeOnboarding()
            }
            .buttonStyle(DJGhostButtonStyle())
            .accessibilityIdentifier("onboarding.skip")

            Spacer()

            Button(step == .ready ? "Finish" : "Continue") {
                advance()
            }
            .buttonStyle(DJPrimaryButtonStyle())
            .disabled(!canContinue)
            .keyboardShortcut(.defaultAction)
            .accessibilityIdentifier(step == .ready ? "onboarding.startSetup" : "onboarding.continue")
        }
    }

    private var installedCount: Int {
        model.installedOrRunningProbeCount
    }

    private var grantedFolderCount: Int {
        model.configuredRecordingsCount
    }

    private var canContinue: Bool {
        switch step {
        case .djApps:
            return installedCount >= 1 || !model.probeResults.isEmpty
        case .folderAccess:
            return grantedFolderCount >= 1
        default:
            return true
        }
    }

    private func advance() {
        if step == .ready {
            model.completeOnboarding(destination: .protection)
            model.scanNow()
            return
        }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }
}

#Preview("Onboarding Welcome / light") {
    OnboardingView(startingStep: .welcome)
        .environmentObject(AppModel())
        .preferredColorScheme(.light)
}

#Preview("Onboarding Welcome / dark") {
    OnboardingView(startingStep: .welcome)
        .environmentObject(AppModel())
        .preferredColorScheme(.dark)
}

#Preview("Onboarding Folder Access · Continue disabled / light") {
    OnboardingView(startingStep: .folderAccess)
        .environmentObject(AppModel())
        .preferredColorScheme(.light)
}

#Preview("Onboarding Ready / dark") {
    onboardingReadyPreview()
}

@MainActor
private func onboardingReadyPreview() -> some View {
    let model = AppModel()
    model.previewApplyConfiguredRecordingsFolders(reachableAppIDs: ["serato"])
    return OnboardingView(startingStep: .ready)
        .environmentObject(model)
        .preferredColorScheme(.dark)
}
