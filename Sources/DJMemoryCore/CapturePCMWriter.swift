import AVFoundation
import Foundation

/// Shared convert-and-write path for Capture PCM buffers (input device + app audio).
public enum CapturePCMWriter {
    /// Converts `buffer` through `converter` into `writeFormat` and writes to `audioFile`.
    /// - Returns: Error detail (without a "Capture" / "App audio Capture" prefix), or `nil` on success.
    public static func convertAndWrite(
        buffer: AVAudioPCMBuffer,
        converter: AVAudioConverter,
        writeFormat: AVAudioFormat,
        audioFile: AVAudioFile
    ) -> String? {
        let ratio = writeFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 32
        guard let converted = AVAudioPCMBuffer(pcmFormat: writeFormat, frameCapacity: max(capacity, 1)) else {
            return "could not allocate a 24-bit / 48 kHz buffer."
        }

        var error: NSError?
        var provided = false
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            if provided {
                outStatus.pointee = .noDataNow
                return nil
            }
            provided = true
            outStatus.pointee = .haveData
            return buffer
        }
        let status = converter.convert(to: converted, error: &error, withInputFrom: inputBlock)
        if status == .error || converted.frameLength == 0 {
            return "could not convert to 24-bit / 48 kHz: \(error?.localizedDescription ?? "unknown error")."
        }
        do {
            try audioFile.write(from: converted)
            return nil
        } catch {
            let nsError = error as NSError
            return "could not write audio: \(error.localizedDescription) [\(nsError.domain)#\(nsError.code)] "
                + "buffer=\(converted.format) file=\(audioFile.processingFormat)"
        }
    }
}
