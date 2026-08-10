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
}
