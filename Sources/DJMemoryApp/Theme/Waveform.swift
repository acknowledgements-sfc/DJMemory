import SwiftUI

struct Waveform: View {
    let seed: String
    var barCount: Int = 64
    var tint: Color = DJToken.primary
    var progress: Double?

    private var bars: [CGFloat] {
        Self.seededAmplitudes(seed: seed, count: clampedBarCount)
    }

    private var clampedBarCount: Int {
        min(80, max(18, barCount))
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 2) {
                ForEach(0..<clampedBarCount, id: \.self) { index in
                    let amplitude = bars[index]
                    let played: Bool = {
                        guard let progress else { return true }
                        return Double(index) / Double(clampedBarCount) <= progress
                    }()
                    let opacity: Double = {
                        if progress == nil {
                            return 0.28 + Double(amplitude) * 0.5
                        }
                        return played ? 0.9 : 0.22
                    }()

                    RoundedRectangle(cornerRadius: 1)
                        .fill(tint.opacity(opacity))
                        .frame(height: max(2, geo.size.height * amplitude))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .accessibilityHidden(true)
    }

    /// Deterministic FNV-1a + xorshift amplitudes in 0.18…1.0 (ported from prototype `ui.tsx`).
    static func seededAmplitudes(seed: String, count: Int) -> [CGFloat] {
        var hash: UInt32 = 2_166_136_261
        for unit in seed.utf8 {
            hash ^= UInt32(unit)
            hash = hash &* 16_777_619
        }

        var bars: [CGFloat] = []
        bars.reserveCapacity(count)
        for index in 0..<count {
            hash ^= hash << 13
            hash ^= hash >> 17
            hash ^= hash << 5
            let noise = CGFloat(abs(Int32(bitPattern: hash) % 1000)) / 1000
            let envelope = 0.55 + 0.45 * sin((CGFloat(index) / CGFloat(count)) * .pi)
            bars.append(0.18 + noise * 0.82 * envelope)
        }
        return bars
    }
}

#Preview("Waveform") {
    VStack(spacing: 16) {
        Waveform(seed: "set-2026-08-06.wav", barCount: 64, tint: DJToken.accent(forAppID: "serato"))
            .frame(height: 24)
        Waveform(seed: "club-night.aiff", barCount: 88, tint: DJToken.accent(forAppID: "rekordbox"), progress: 0.45)
            .frame(height: 56)
            .padding(8)
            .background(DJToken.muted, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
    }
    .padding()
    .frame(width: 420)
    .background(DJToken.content)
}
