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
    /// Canonical 24-bit / 48 kHz write target; also the format the pre-roll ring is stored in.
    private var writeFormat: AVAudioFormat?
    /// Adapted Float32 source format of the current ScreenCaptureKit stream.
    private var sourceFormat: AVAudioFormat?
    private var converter: AVAudioConverter?
    private var lastFormatMismatchDetail: String?

    /// Ring of already-converted `writeFormat` buffers captured while watching, flushed into the
    /// file on `beginRecordingFile` so a take starts at the true first signal rather than ~half a
    /// second in (after the silence-session start hold). Only mutated on `sampleHandlerQueue`.
    private var prerollBuffers: [AVAudioPCMBuffer] = []
    private var prerollFrames: AVAudioFrameCount = 0
    private var prerollFrameBudget: AVAudioFrameCount = 0

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

    public func startMonitoring(
        bundleIdentifier: String,
        displayName: String,
        prerollSeconds: TimeInterval = 1.0
    ) async throws {
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
        configuration.sampleRate = Int(CaptureAudioFormat.sampleRate)
        configuration.channelCount = Int(CaptureAudioFormat.channelCount)
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
        // Canonical write target; the pre-roll ring stores buffers already converted to this format
        // so a take can begin with the audio that played during the silence-session start hold.
        writeFormat = CaptureAudioFormat.processingFormat()
        sourceFormat = nil
        converter = nil
        sampleHandlerQueue.sync {
            prerollBuffers.removeAll()
            prerollFrames = 0
            prerollFrameBudget = AVAudioFrameCount(max(0, prerollSeconds) * CaptureAudioFormat.sampleRate)
        }
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
        writeFormat = nil
        sourceFormat = nil
        converter = nil
        sampleHandlerQueue.sync {
            prerollBuffers.removeAll()
            prerollFrames = 0
        }
        setInputLevel(0)
    }

    public func beginRecordingFile() throws {
        guard isMonitoring else { throw AppAudioCaptureError.notMonitoring }
        guard !isWriting else { throw AppAudioCaptureError.alreadyWriting }

        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        let url = stagingDirectory.appendingPathComponent("app-audio-\(UUID().uuidString).wav")
        let newAudioFile: AVAudioFile
        do {
            newAudioFile = try AVAudioFile(forWriting: url, settings: CaptureAudioFormat.writeSettings)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(ENOSPC) {
                throw AppAudioCaptureError.diskFull
            }
            throw AppAudioCaptureError.engineFailed(error.localizedDescription)
        }
        // AVAudioFile.write(from:) requires the buffer format to match the file's own
        // processingFormat (Float32 deinterleaved) — it packs down to the on-disk `settings`
        // bit depth internally. The pre-roll ring and stream converter already target this format.
        let fileFormat = newAudioFile.processingFormat

        // Flush the pre-roll and flip to writing atomically on the sample-handler queue so no live
        // buffer is written before the buffered start, and no callback races the file swap.
        sampleHandlerQueue.sync {
            var flushedFrames: AVAudioFrameCount = 0
            if let writeFormat, fileFormat.isEqual(writeFormat) {
                for buffer in prerollBuffers {
                    if AppAudioCaptureService.writeSucceeded(buffer, to: newAudioFile) {
                        flushedFrames += buffer.frameLength
                    }
                }
            }
            prerollBuffers.removeAll()
            prerollFrames = 0
            audioFile = newAudioFile
            // Backdate the start by the flushed pre-roll so the archive timestamp lands on the
            // true first signal rather than the moment the start hold elapsed.
            let prerollDuration = Double(flushedFrames) / CaptureAudioFormat.sampleRate
            startedAt = Date().addingTimeInterval(-prerollDuration)
            isWriting = true
        }
        stagingURL = url
        lastFormatMismatchDetail = nil
    }

    private static func writeSucceeded(_ buffer: AVAudioPCMBuffer, to audioFile: AVAudioFile) -> Bool {
        CapturePCMWriter.write(buffer: buffer, to: audioFile) == nil
    }

    public func endRecordingFile(discard: Bool = false) throws -> CaptureResult? {
        guard isWriting else { throw AppAudioCaptureError.notWriting }
        // Stop writing on the sample-handler queue so no in-flight callback writes to a closed file.
        // Keep `writeFormat`/`converter` so metering and the pre-roll ring keep running while armed.
        sampleHandlerQueue.sync {
            audioFile = nil
            isWriting = false
        }
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

        // Convert every buffer while monitoring — not only while writing — so the pre-roll ring
        // always holds the most recent audio ready to prepend to the next take.
        guard let writeFormat else { return }

        let frameLength = AVAudioFrameCount(CMSampleBufferGetNumSamples(sampleBuffer))
        guard frameLength > 0 else { return }

        if !isFloat {
            lastFormatMismatchDetail = "App audio Capture received non-float audio buffers. Arm again, or use Input device Capture."
            return
        }

        // Rebuild converter when ScreenCaptureKit delivers a different rate/channel layout.
        let sourceRate = asbd.mSampleRate
        let sourceChannelCount = AVAudioChannelCount(max(1, sourceChannels))
        if sourceFormat == nil
            || abs(sourceRate - (sourceFormat?.sampleRate ?? 0)) > 0.5
            || sourceChannelCount != sourceFormat?.channelCount {
            guard let adaptedSource = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sourceRate,
                channels: sourceChannelCount,
                interleaved: false
            ),
                let adaptedConverter = CaptureAudioFormat.makeConverter(from: adaptedSource, to: writeFormat)
            else {
                lastFormatMismatchDetail = "App audio Capture received an unsupported buffer format (\(Int(sourceRate)) Hz, \(sourceChannels) ch). Arm again, or use Input device Capture."
                return
            }
            self.sourceFormat = adaptedSource
            self.converter = adaptedConverter
        }

        guard let activeSource = self.sourceFormat,
              let activeConverter = self.converter,
              let pcm = AVAudioPCMBuffer(pcmFormat: activeSource, frameCapacity: frameLength)
        else { return }
        pcm.frameLength = frameLength

        let channelCount = Int(activeSource.channelCount)
        guard let floatChannels = pcm.floatChannelData else { return }

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

        let conversion = CapturePCMWriter.convert(buffer: pcm, converter: activeConverter, writeFormat: writeFormat)
        if let detail = conversion.error {
            lastFormatMismatchDetail = "App audio Capture \(detail)"
            return
        }
        guard let converted = conversion.buffer else {
            lastFormatMismatchDetail = "App audio Capture could not convert to 24-bit / 48 kHz."
            return
        }

        if isWriting, let audioFile {
            if let detail = CapturePCMWriter.write(buffer: converted, to: audioFile) {
                lastFormatMismatchDetail = "App audio Capture \(detail)"
            } else {
                lastFormatMismatchDetail = nil
            }
        } else {
            appendPreroll(converted)
            lastFormatMismatchDetail = nil
        }
    }

    /// Appends a converted buffer to the pre-roll ring and trims it to the frame budget.
    /// Must run on `sampleHandlerQueue`.
    private func appendPreroll(_ buffer: AVAudioPCMBuffer) {
        guard prerollFrameBudget > 0 else { return }
        prerollBuffers.append(buffer)
        prerollFrames += buffer.frameLength
        while prerollFrames > prerollFrameBudget, prerollBuffers.count > 1 {
            let removed = prerollBuffers.removeFirst()
            prerollFrames -= min(prerollFrames, removed.frameLength)
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
        sourceFormat = nil
        converter = nil
        stagingURL = nil
        startedAt = nil
        prerollBuffers.removeAll()
        prerollFrames = 0
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
