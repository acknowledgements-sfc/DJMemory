import AVFoundation
import Foundation

/// Canonical capture write format: 24-bit linear PCM stereo at 48 kHz.
public enum CaptureAudioFormat {
    public static let sampleRate: Double = 48_000
    public static let channelCount: AVAudioChannelCount = 2
    public static let bitDepth: Int = 24

    public static var writeSettings: [String: Any] {
        [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: Int(channelCount),
            AVLinearPCMBitDepthKey: bitDepth,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
    }

    public static func writeFormat() -> AVAudioFormat? {
        AVAudioFormat(settings: writeSettings)
    }

    /// Float32 non-interleaved processing format at the capture sample rate (metering / silence).
    public static func processingFormat(channels: AVAudioChannelCount = channelCount) -> AVAudioFormat? {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        )
    }

    public static func makeConverter(from source: AVAudioFormat, to destination: AVAudioFormat) -> AVAudioConverter? {
        AVAudioConverter(from: source, to: destination)
    }
}
