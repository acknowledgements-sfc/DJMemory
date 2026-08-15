import AppKit
import SwiftUI

struct MenuBarStatusView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            captureStatusSection

            if let warning = model.folderHealthWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                    .accessibilityIdentifier("menuBar.folderHealthWarning")
            }

            if model.settings.showFolderScanDetailsInMenuBar {
                Divider()
                scanDetailsSection
            }

            Divider()

            actionsSection
        }
        .padding(12)
        .frame(width: 300, alignment: .leading)
    }

    // MARK: Capture status

    @ViewBuilder
    private var captureStatusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(stateHeadline, systemImage: model.menuBarState.symbolName)
                .font(.headline)
                .foregroundStyle(model.menuBarState.tint ?? .primary)
                .accessibilityIdentifier("menuBar.captureState")

            if model.recordingStartedAt != nil {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Label("Recording — \(model.menuBarElapsedText ?? "0:00")", systemImage: "record.circle")
                        .foregroundStyle(.red)
                        .font(.caption)
                        .accessibilityIdentifier("menuBar.recordingElapsed")
                }
            }

            if let previous = model.previousCaptureSummary {
                Label(previous, systemImage: model.lastCaptureIsFailure ? "xmark.circle" : "checkmark.circle")
                    .foregroundStyle(model.lastCaptureIsFailure ? .orange : .secondary)
                    .font(.caption)
                    .accessibilityIdentifier("menuBar.previousCapture")
            } else {
                Text("No captures yet")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .accessibilityIdentifier("menuBar.previousCapture")
            }
        }
    }

    private var stateHeadline: String {
        switch model.menuBarState {
        case .launching: return "Starting up…"
        case .ready: return "Ready — no DJ app detected"
        case .armed(let name): return name.map { "\($0) — armed" } ?? "Armed"
        case .capturing(let name): return name.map { "Capturing \($0)" } ?? "Capturing"
        case .saving: return "Saving…"
        case .saved: return "Saved"
        case .failed(let reason): return "Error: \(reason)"
        }
    }

    // MARK: Legacy scan details (opt-in, off by default)

    private var scanDetailsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(model.headlineStatus, systemImage: model.protectionSymbolName)
                .font(.subheadline)
                .accessibilityIdentifier("menuBar.headlineStatus")
            Label("Last scan: \(model.lastScanDisplayText)", systemImage: "checkmark.circle")
                .accessibilityIdentifier("menuBar.lastScan")
            Label("Next scan: \(model.nextScanDisplayText)", systemImage: "clock")
                .accessibilityIdentifier("menuBar.nextScan")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: Actions

    @ViewBuilder
    private var actionsSection: some View {
        if model.menuBarState.isPulsing {
            Button(role: .destructive) {
                model.stopCapture()
            } label: {
                Label("Stop Capture", systemImage: "stop.circle")
            }
            .accessibilityIdentifier("menuBar.stopCapture")
        }

        Button {
            model.openMainWindow()
        } label: {
            Label("Open Main Window", systemImage: "macwindow")
        }
        .accessibilityIdentifier("menuBar.openMainWindow")

        Button {
            model.viewLastCaptureInMainWindow()
        } label: {
            Label("View Last Capture in Main Window", systemImage: "waveform")
        }
        .disabled(model.lastCaptureSession == nil)
        .accessibilityIdentifier("menuBar.viewLastCaptureInMainWindow")

        Button {
            model.viewLastCaptureInFinder()
        } label: {
            Label("View Last Capture in Finder", systemImage: "folder")
        }
        .disabled(model.lastCaptureSession == nil)
        .accessibilityIdentifier("menuBar.viewLastCaptureInFinder")

        Divider()

        Button {
            model.openMainWindow()
            model.selectedRoute = .settings
        } label: {
            Label("App Settings", systemImage: "gearshape")
        }
        .accessibilityIdentifier("menuBar.appSettings")

        Button {
            NSApp.terminate(nil)
        } label: {
            Label("Quit App", systemImage: "power")
        }
        .accessibilityIdentifier("menuBar.quit")
    }
}
