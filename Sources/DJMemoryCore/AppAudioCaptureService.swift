#if os(macOS)
import AVFoundation
import CoreGraphics
import CoreMedia
import Foundation
import ScreenCaptureKit

public enum AppAudioCaptureError: Error, Equatable, Sendable {
    case permissionDenied
    case appNotShareable(String)
    case noDisplay
    case alreadyMonitoring
    case notMonitoring
    case alreadyWriting
    case notWriting
    case engineFailed(String)
    case diskFull
    case streamStopped(String)
}

/// Captures a single macOS app's audio via ScreenCaptureKit into staging WAVs.
public final class AppAudioCaptureService: NSObject, @unchecked Sendable {
    public private(set) var isMonitoring = false
    public private(set) var isWriting = false
    public private(set) var inputLevel: Float = 0
    public private(set) var startedAt: Date?
    public private(set) var targetBundleIdentifier = ""
    public private(set) var targetDisplayName = ""

    /// Invoked on the sample-handler queue when ScreenCaptureKit stops the stream with an error.
    public var onStreamStopped: ((AppAudioCaptureError) -> Void)?

    private let fileManager: FileManager
    private let stagingDirectory: URL
    private let sampleHandlerQueue = DispatchQueue(label: "app.djmemory.AppAudioCapture.sample")
    private let levelLock = NSLock()
    private var stream: SCStream?
    private var audioFile: AVAudioFile?
    private var stagingURL: URL?
    private var writeFormat: AVAudioFormat?
    private var lastFormatMismatchDetail: String?

    public init(stagingDirectory: URL = CaptureService.defaultStagingDirectory(), fileManager: FileManager = .default) {
        self.stagingDirectory = stagingDirectory
        self.fileManager = fileManager
        super.init()
    }

    public static func screenCapturePermissionGranted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    public static func requestScreenCapturePermission() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    public func listShareableDJApps() async throws -> [MatchedDJApp] {
        let content = try await fetchShareableContent()
        let bundleIDs = content.applications.compactMap(\.bundleIdentifier)
        return DJAppProcessMatcher.matchRunning(bundleIdentifiers: bundleIDs)
    }

    public func startMonitoring(bundleIdentifier: String, displayName: String) async throws {
        guard !isMonitoring else { throw AppAudioCaptureError.alreadyMonitoring }
        if !Self.screenCapturePermissionGranted() {
            let granted = Self.requestScreenCapturePermission()
            // CGRequestScreenCaptureAccess often returns false before Settings toggles apply.
            if !granted && !Self.screenCapturePermissionGranted() {
                throw AppAudioCaptureError.permissionDenied
            }
        }

        let content = try await fetchShareableContent()

        guard let runningApp = content.applications.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            throw AppAudioCaptureError.appNotShareable(displayName)
        }
        guard let display = content.displays.first else {
            throw AppAudioCaptureError.noDisplay
        }

        let filter = SCContentFilter(display: display, including: [runningApp], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.sampleRate = 48_000
        configuration.channelCount = 2
        configuration.width = 2
        configuration.height = 2
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        configuration.queueDepth = 8

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        do {
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: sampleHandlerQueue)
            try await stream.startCapture()
        } catch {
            throw AppAudioCaptureError.engineFailed(error.localizedDescription)
        }

        self.stream = stream
        targetBundleIdentifier = bundleIdentifier
        targetDisplayName = displayName
        isMonitoring = true
        lastFormatMismatchDetail = nil
        setInputLevel(0)
    }

    public func stopMonitoring() async {
        guard isMonitoring else { return }
        if isWriting {
            _ = try? endRecordingFile(discard: true)
        }
        if let stream {
            try? await stream.stopCapture()
        }
        stream = nil
        isMonitoring = false
        targetBundleIdentifier = ""
        targetDisplayName = ""
        setInputLevel(0)
    }

    public func beginRecordingFile() throws {
        guard isMonitoring else { throw AppAudioCaptureError.notMonitoring }
        guard !isWriting else { throw AppAudioCaptureError.alreadyWriting }

        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        let url = stagingDirectory.appendingPathComponent("app-audio-\(UUID().uuidString).wav")
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000, channels: 2, interleaved: false) else {
            throw AppAudioCaptureError.engineFailed("Could not create capture audio format.")
        }
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(ENOSPC) {
                throw AppAudioCaptureError.diskFull
            }
            throw AppAudioCaptureError.engineFailed(error.localizedDescription)
        }
        writeFormat = format
        stagingURL = url
        startedAt = Date()
        isWriting = true
        lastFormatMismatchDetail = nil
    }

    public func endRecordingFile(discard: Bool = false) throws -> CaptureResult? {
        guard isWriting else { throw AppAudioCaptureError.notWriting }
        audioFile = nil
        writeFormat = nil
        isWriting = false
        let endedAt = Date()
        let started = startedAt ?? endedAt
        startedAt = nil
        guard let stagingURL else {
            throw AppAudioCaptureError.engineFailed("Capture staging file is missing.")
        }
        self.stagingURL = nil

        if discard {
            try? fileManager.removeItem(at: stagingURL)
            return nil
        }

        if let detail = lastFormatMismatchDetail {
            try? fileManager.removeItem(at: stagingURL)
            throw AppAudioCaptureError.engineFailed(detail)
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: stagingURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw AppAudioCaptureError.engineFailed("Capture staging file is missing.")
        }

        return CaptureResult(
            stagingURL: stagingURL,
            deviceID: targetBundleIdentifier,
            deviceName: "\(targetDisplayName) app audio",
            startedAt: started,
            endedAt: endedAt
        )
    }

    public func currentInputLevel() -> Float {
        levelLock.lock(); defer { levelLock.unlock() }
        return inputLevel
    }

    private func setInputLevel(_ value: Float) {
        levelLock.lock()
        inputLevel = value
        levelLock.unlock()
    }

    private func fetchShareableContent() async throws -> SCShareableContent {
        do {
            return try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        } catch {
            if Self.isScreenCapturePermissionError(error) || !Self.screenCapturePermissionGranted() {
                throw AppAudioCaptureError.permissionDenied
            }
            throw AppAudioCaptureError.engineFailed(error.localizedDescription)
        }
    }

    static func isScreenCapturePermissionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let text = (nsError.localizedDescription + " " + (nsError.localizedFailureReason ?? "")).lowercased()
        if text.contains("permission") || text.contains("not authorized") || text.contains("tcc")
            || text.contains("screen capture") || text.contains("denied")
        {
            return true
        }
        // ScreenCaptureKit commonly uses SCStreamError / CGError domain codes for denied access.
        if nsError.domain.contains("ScreenCapture") || nsError.domain.contains("SCStream") {
            return nsError.code == Int(CGError.failure.rawValue) || nsError.code == -3801 || nsError.code == -3802
        }
        return false
    }

    private func handleAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard sampleBuffer.isValid, let formatDescription = sampleBuffer.formatDescription else { return }
        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee
        guard let asbd else { return }

        var bufferListSizeNeeded = 0
        var blockBuffer: CMBlockBuffer?
        var status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: &bufferListSizeNeeded,
            bufferListOut: nil,
            bufferListSize: 0,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        guard status == noErr, bufferListSizeNeeded > 0 else { return }

        let raw = UnsafeMutableRawPointer.allocate(byteCount: bufferListSizeNeeded, alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        let audioBufferList = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
        status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: audioBufferList,
            bufferListSize: bufferListSizeNeeded,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        guard status == noErr else { return }

        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let isFloat = asbd.mFormatFlags & kAudioFormatFlagIsFloat != 0
        let isInterleaved = asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved == 0
        let sourceChannels = Int(asbd.mChannelsPerFrame)

        var sumSquares: Float = 0
        var sampleCount = 0
        if isFloat {
            for buffer in ablPointer {
                guard let data = buffer.mData else { continue }
                let frameCount = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
                let samples = data.bindMemory(to: Float.self, capacity: frameCount)
                for i in 0..<frameCount {
                    let s = samples[i]
                    sumSquares += s * s
                }
                sampleCount += frameCount
            }
        }
        if sampleCount > 0 {
            let rms = sqrt(sumSquares / Float(sampleCount))
            setInputLevel(min(1, rms * 4))
        }

        guard isWriting, let audioFile, let writeFormat else { return }

        let frameLength = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frameLength > 0 else { return }

        // Adapt write format once if SCK delivers a different rate/channel layout.
        if abs(asbd.mSampleRate - writeFormat.sampleRate) > 0.5 || sourceChannels != Int(writeFormat.channelCount) {
            if !reconfigureWriteFormat(sampleRate: asbd.mSampleRate, channels: AVAudioChannelCount(max(1, sourceChannels))) {
                lastFormatMismatchDetail = "App audio Capture received an unsupported buffer format (\(Int(asbd.mSampleRate)) Hz, \(sourceChannels) ch). Arm again, or use Input device Capture."
                return
            }
        }

        guard let activeFormat = self.writeFormat,
              let pcm = AVAudioPCMBuffer(pcmFormat: activeFormat, frameCapacity: frameLength)
        else { return }
        pcm.frameLength = frameLength

        let channelCount = Int(activeFormat.channelCount)
        guard let floatChannels = pcm.floatChannelData else { return }

        if !isFloat {
            lastFormatMismatchDetail = "App audio Capture received non-float audio buffers. Arm again, or use Input device Capture."
            return
        }

        if isInterleaved, ablPointer.count >= 1, let src = ablPointer[0].mData {
            let interleaved = src.bindMemory(to: Float.self, capacity: Int(frameLength) * max(sourceChannels, 1))
            for frame in 0..<Int(frameLength) {
                for channel in 0..<channelCount {
                    let srcChannel = min(channel, max(sourceChannels, 1) - 1)
                    floatChannels[channel][frame] = interleaved[frame * max(sourceChannels, 1) + srcChannel]
                }
            }
        } else {
            for channel in 0..<channelCount {
                let srcIndex = min(channel, ablPointer.count - 1)
                guard srcIndex >= 0, let src = ablPointer[srcIndex].mData else { continue }
                let count = min(Int(frameLength), Int(ablPointer[srcIndex].mDataByteSize) / MemoryLayout<Float>.size)
                memcpy(floatChannels[channel], src, count * MemoryLayout<Float>.size)
            }
        }

        do {
            try audioFile.write(from: pcm)
            lastFormatMismatchDetail = nil
        } catch {
            lastFormatMismatchDetail = "App audio Capture could not write audio: \(error.localizedDescription)"
        }
    }

    private func reconfigureWriteFormat(sampleRate: Double, channels: AVAudioChannelCount) -> Bool {
        guard isWriting, let stagingURL else { return false }
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: channels, interleaved: false) else {
            return false
        }
        // Restart the staging file with the observed format so subsequent buffers write cleanly.
        audioFile = nil
        do {
            try? fileManager.removeItem(at: stagingURL)
            audioFile = try AVAudioFile(forWriting: stagingURL, settings: format.settings)
            writeFormat = format
            return true
        } catch {
            lastFormatMismatchDetail = "App audio Capture could not adapt to \(Int(sampleRate)) Hz / \(channels) ch: \(error.localizedDescription)"
            return false
        }
    }
}

extension AppAudioCaptureService: SCStreamDelegate {
    public func stream(_ stream: SCStream, didStopWithError error: Error) {
        let wasMonitoring = isMonitoring
        let wasWriting = isWriting
        isMonitoring = false
        isWriting = false
        audioFile = nil
        writeFormat = nil
        stagingURL = nil
        startedAt = nil
        setInputLevel(0)
        guard wasMonitoring || wasWriting else { return }
        let captureError = AppAudioCaptureError.streamStopped(error.localizedDescription)
        onStreamStopped?(captureError)
    }
}

extension AppAudioCaptureService: SCStreamOutput {
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        handleAudioSampleBuffer(sampleBuffer)
    }
}
#endif
