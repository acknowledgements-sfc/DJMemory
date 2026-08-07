import SwiftUI
import DJMemoryCore

struct Badge: View {
    let title: String
    var tone: StatusTone = .neutral

    var body: some View {
        Text(title)
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
        Badge(title: status.displayName, tone: tone)
    }
}

#Preview("Badge tones") {
    HStack(spacing: 8) {
        Badge(title: "Matched", tone: .ok)
        Badge(title: "Partial", tone: .warn)
        Badge(title: "Attention", tone: .danger)
        Badge(title: "Scanning", tone: .info)
        Badge(title: "Research", tone: .neutral)
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
