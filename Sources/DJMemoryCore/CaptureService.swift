import AVFoundation
import Foundation

public enum CaptureServiceError: Error, Equatable, Sendable {
    case permissionDenied
    case deviceMissing
    case diskFull
    case engineFailed(String)
    case alreadyRecording
    case notRecording
}

public struct CaptureResult: Equatable, Sendable {
    public let stagingURL: URL
    public let deviceID: String
    public let deviceName: String
    public let startedAt: Date
    public let endedAt: Date

    public init(stagingURL: URL, deviceID: String, deviceName: String, startedAt: Date, endedAt: Date) {
        self.stagingURL = stagingURL
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
}

public final class CaptureService: @unchecked Sendable {
    public private(set) var isRecording = false
    public private(set) var inputLevel: Float = 0
    public private(set) var startedAt: Date?

    private let fileManager: FileManager
    private let stagingDirectory: URL
    private let engine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var stagingURL: URL?
    private var deviceID = ""
    private var deviceName = ""
    private let levelLock = NSLock()

    public init(stagingDirectory: URL = CaptureService.defaultStagingDirectory(), fileManager: FileManager = .default) {
        self.stagingDirectory = stagingDirectory
        self.fileManager = fileManager
    }

    public static func defaultStagingDirectory() -> URL {
        DefaultPathProvider().applicationSupportDirectory()
            .appendingPathComponent("CaptureStaging", isDirectory: true)
    }

    public static func microphonePermissionGranted() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    public static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    public func start(device: AudioInputDevice) throws {
        guard !isRecording else { throw CaptureServiceError.alreadyRecording }
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status != .authorized { throw CaptureServiceError.permissionDenied }

        try fileManager.createDirectory(at: stagingDirectory, withIntermediateDirectories: true)
        let url = stagingDirectory.appendingPathComponent("capture-\(UUID().uuidString).wav")
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw CaptureServiceError.engineFailed("Input device has no usable audio format.")
        }

        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSPOSIXErrorDomain && nsError.code == Int(ENOSPC) { throw CaptureServiceError.diskFull }
            throw CaptureServiceError.engineFailed(error.localizedDescription)
        }

        stagingURL = url
        deviceID = device.id
        deviceName = device.name
        startedAt = Date()
        inputLevel = 0
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            try? self.audioFile?.write(from: buffer)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }
            var sum: Float = 0
            for i in 0..<frameLength { let s = channelData[i]; sum += s * s }
            let rms = sqrt(sum / Float(frameLength))
            self.levelLock.lock(); self.inputLevel = min(1, rms * 4); self.levelLock.unlock()
        }

        do {
            try engine.start()
        } catch {
            inputNode.removeTap(onBus: 0)
            audioFile = nil
            if let stagingURL { try? fileManager.removeItem(at: stagingURL) }
            self.stagingURL = nil
            startedAt = nil
            throw CaptureServiceError.engineFailed(error.localizedDescription)
        }
        isRecording = true
    }

    public func stop() throws -> CaptureResult {
        guard isRecording else { throw CaptureServiceError.notRecording }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioFile = nil
        isRecording = false
        let endedAt = Date()
        let started = startedAt ?? endedAt
        startedAt = nil
        guard let stagingURL else { throw CaptureServiceError.engineFailed("Capture staging file is missing.") }
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: stagingURL.path, isDirectory: &isDirectory), !isDirectory.boolValue else {
            throw CaptureServiceError.engineFailed("Capture staging file is missing.")
        }
        let result = CaptureResult(stagingURL: stagingURL, deviceID: deviceID, deviceName: deviceName, startedAt: started, endedAt: endedAt)
        self.stagingURL = nil
        return result
    }

    public func currentInputLevel() -> Float {
        levelLock.lock(); defer { levelLock.unlock() }
        return inputLevel
    }
}
