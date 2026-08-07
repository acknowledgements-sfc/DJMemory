import SwiftUI
import DJMemoryCore

struct StatusDot: View {
    let tone: StatusTone
    var pulse: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.55, paused: !pulse)) { context in
            let blinkOn = !pulse || Int(context.date.timeIntervalSinceReferenceDate / 0.55) % 2 == 0
            Circle()
                .fill(tone.color)
                .frame(width: 6, height: 6)
                .opacity(blinkOn ? 1 : 0.35)
        }
        .frame(width: 8, height: 8)
        .accessibilityHidden(true)
    }
}

struct SupportBadge: View {
    let status: IntegrationSupportStatus

    private var tone: StatusTone {
        switch status {
        case .supported:
            return .ok
        case .partial:
            return .warn
        case .manualSetup, .research:
            return .neutral
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.system(size: DJToken.TypeSize.micro, weight: .semibold))
            .tracking(0.2)
            .foregroundStyle(tone.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(tone.color.opacity(0.1), in: RoundedRectangle(cornerRadius: DJToken.Radius.badge))
            .overlay(
                RoundedRectangle(cornerRadius: DJToken.Radius.badge)
                    .stroke(tone.color.opacity(0.35), lineWidth: 1)
            )
    }
}

#Preview("StatusDot tones") {
    HStack(spacing: 12) {
        StatusDot(tone: .ok)
        StatusDot(tone: .warn)
        StatusDot(tone: .danger)
        StatusDot(tone: .info, pulse: true)
        StatusDot(tone: .neutral)
    }
    .padding()
}

#Preview("SupportBadge") {
    HStack(spacing: 8) {
        SupportBadge(status: .supported)
        SupportBadge(status: .partial)
        SupportBadge(status: .manualSetup)
        SupportBadge(status: .research)
    }
    .padding()
}
