import Foundation

/// Engine actions the host (AppModel) must perform — coordinator never touches ScreenCaptureKit.
public enum CaptureSessionEngineAction: Equatable, Sendable {
    case beginRecordingFile
    case endRecordingFile(discard: Bool)
}

/// One tick of Capture session policy: phase + meter + optional engine action.
public struct CaptureSessionTick: Equatable, Sendable {
    public var phase: CapturePhase
    public var inputLevel: Float
    public var statusMessage: String
    public var engineAction: CaptureSessionEngineAction?

    public init(
        phase: CapturePhase,
        inputLevel: Float = 0,
        statusMessage: String,
        engineAction: CaptureSessionEngineAction? = nil
    ) {
        self.phase = phase
        self.inputLevel = inputLevel
        self.statusMessage = statusMessage
        self.engineAction = engineAction
    }
}

/// Deep module for App audio Capture session control: silence FSM → phase → engine actions.
/// AppModel stays the adapter for permissions, ingest, notifications, and Task polling.
public struct CaptureSessionCoordinator: Equatable, Sendable {
    private var silence: SilenceSessionController
    private var phase: CapturePhase
    private var targetDisplayName: String

    public init(config: SilenceSessionConfig = .default) {
        self.silence = SilenceSessionController(config: config)
        self.phase = .idle
        self.targetDisplayName = ""
    }

    public var currentPhase: CapturePhase { phase }

    public mutating func prepareWatching(config: SilenceSessionConfig, targetDisplayName: String) -> CaptureSessionTick {
        silence = SilenceSessionController(config: config)
        self.targetDisplayName = targetDisplayName
        phase = .watching
        return CaptureSessionTick(
            phase: .watching,
            statusMessage: "Watching \(targetDisplayName). Recording starts when audio is detected; idle silence saves the take automatically."
        )
    }

    public mutating func disarm(hasTargets: Bool) -> CaptureSessionTick {
        silence.resetToArmed()
        phase = hasTargets ? .armed : .idle
        return CaptureSessionTick(
            phase: phase,
            statusMessage: "App audio Capture is disarmed. Folder Protection still watches recording folders."
        )
    }

    /// Feed RMS from the capture engine while watching or recording.
    public mutating func tick(level: Float, now: Date = Date()) -> CaptureSessionTick {
        guard phase == .watching || phase == .recording else {
            return CaptureSessionTick(phase: phase, inputLevel: level, statusMessage: "")
        }

        let event = silence.process(level: level, now: now)
        switch event {
        case .none:
            return CaptureSessionTick(
                phase: phase,
                inputLevel: level,
                statusMessage: phase == .recording
                    ? "Recording \(targetDisplayName) app audio…"
                    : "Watching \(targetDisplayName). Recording starts when audio is detected; idle silence saves the take automatically."
            )

        case .startedRecording:
            phase = .recording
            return CaptureSessionTick(
                phase: .recording,
                inputLevel: level,
                statusMessage: "Recording \(targetDisplayName) app audio…",
                engineAction: .beginRecordingFile
            )

        case .finalizeSession(_, let discard):
            phase = .saving
            return CaptureSessionTick(
                phase: .saving,
                inputLevel: level,
                statusMessage: discard ? "Discarding short take…" : "Saving app audio into your archive…",
                engineAction: .endRecordingFile(discard: discard)
            )
        }
    }

    /// Manual Stop while recording: finalize without discard (host still performs endRecordingFile).
    public mutating func requestManualSave() -> CaptureSessionTick {
        silence.resetToArmed()
        phase = .saving
        return CaptureSessionTick(
            phase: .saving,
            statusMessage: "Saving app audio into your archive…",
            engineAction: .endRecordingFile(discard: false)
        )
    }

    public mutating func resumeWatchingAfterSave(discarded: Bool, minDurationSeconds: TimeInterval, level: Float) -> CaptureSessionTick {
        phase = .watching
        let message = discarded
            ? "Short take discarded (under \(Int(minDurationSeconds))s). Still watching."
            : "App audio saved. Watching for the next set. Source DJ app files were not moved."
        return CaptureSessionTick(phase: .watching, inputLevel: level, statusMessage: message)
    }

    public mutating func resumeWatchingAfterManualSave(level: Float) -> CaptureSessionTick {
        phase = .watching
        return CaptureSessionTick(
            phase: .watching,
            inputLevel: level,
            statusMessage: "Manual stop saved. Still watching for the next set."
        )
    }
}
