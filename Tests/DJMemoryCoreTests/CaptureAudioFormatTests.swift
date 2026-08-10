import AVFoundation
import XCTest
@testable import DJMemoryCore

final class CaptureAudioFormatTests: XCTestCase {
    func testWriteSettingsAre24Bit48kStereo() {
        let settings = CaptureAudioFormat.writeSettings
        XCTAssertEqual(settings[AVSampleRateKey] as? Double, 48_000)
        XCTAssertEqual(settings[AVNumberOfChannelsKey] as? Int, 2)
        XCTAssertEqual(settings[AVLinearPCMBitDepthKey] as? Int, 24)
        XCTAssertEqual(settings[AVLinearPCMIsFloatKey] as? Bool, false)
        XCTAssertEqual(settings[AVFormatIDKey] as? AudioFormatID, kAudioFormatLinearPCM)
    }

    func testWriteFormatAndConverterCanBeCreated() throws {
        let write = try XCTUnwrap(CaptureAudioFormat.writeFormat())
        let processing = try XCTUnwrap(CaptureAudioFormat.processingFormat())
        XCTAssertEqual(write.sampleRate, 48_000, accuracy: 0.1)
        XCTAssertEqual(Int(write.streamDescription.pointee.mBitsPerChannel), 24)
        XCTAssertNotNil(CaptureAudioFormat.makeConverter(from: processing, to: write))
    }

    func testCapturePCMWriterConvertsSilenceBuffer() throws {
        let processing = try XCTUnwrap(CaptureAudioFormat.processingFormat())
        let frameLength: AVAudioFrameCount = 480
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: processing, frameCapacity: frameLength))
        buffer.frameLength = frameLength
        if let channels = buffer.floatChannelData {
            for channel in 0..<Int(processing.channelCount) {
                memset(channels[channel], 0, Int(frameLength) * MemoryLayout<Float>.size)
            }
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("djmemory-pcm-writer-\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // AVAudioFile.processingFormat is typically Float32; convert into that for a round-trip write.
        let audioFile = try AVAudioFile(
            forWriting: tempURL,
            settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: CaptureAudioFormat.sampleRate,
                AVNumberOfChannelsKey: Int(CaptureAudioFormat.channelCount),
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: true
            ]
        )
        let writeFormat = audioFile.processingFormat
        let converter = try XCTUnwrap(CaptureAudioFormat.makeConverter(from: processing, to: writeFormat))
        let errorDetail = CapturePCMWriter.convertAndWrite(
            buffer: buffer,
            converter: converter,
            writeFormat: writeFormat,
            audioFile: audioFile
        )
        XCTAssertNil(errorDetail)
        XCTAssertGreaterThan(audioFile.length, 0)
    }
}
