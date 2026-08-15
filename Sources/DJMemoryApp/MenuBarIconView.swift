import SwiftUI

/// Renders the menu bar status item's icon + optional label, animating
/// the flashing (launching) and slow pulsing (capturing) states.
struct MenuBarIconView: View {
    let state: MenuBarState

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !state.isFlashing && !state.isPulsing)) { context in
            let opacity = animatedOpacity(at: context.date)
            HStack(spacing: 4) {
                Image(systemName: state.symbolName)
                    .foregroundStyle(state.tint ?? .primary)
                    .opacity(opacity)
                if let label = state.label {
                    Text(label)
                        .foregroundStyle(state.labelColor)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }
            }
            .accessibilityLabel(state.accessibilityDescription)
        }
    }

    private func animatedOpacity(at date: Date) -> Double {
        guard state.isFlashing || state.isPulsing else { return 1.0 }
        let period: Double = state.isFlashing ? 0.6 : 2.0
        let floor: Double = state.isFlashing ? 0.15 : 0.45
        let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        let wave = (sin(phase * 2 * .pi) + 1) / 2
        return floor + wave * (1.0 - floor)
    }
}
