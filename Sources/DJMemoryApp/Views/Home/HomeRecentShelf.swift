import SwiftUI
import DJMemoryCore

struct HomeRecentShelf: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Panel(title: "Recent sets", padding: 12) {
            if model.librarySummaries.isEmpty {
                Text("No recent sets yet.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.mutedForeground)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(model.librarySummaries.sorted(by: { $0.archive.detectedAt > $1.archive.detectedAt }).prefix(6)) { summary in
                            Button {
                                model.selectedRoute = .library
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Waveform(
                                        seed: summary.archive.originalFilename,
                                        barCount: 28,
                                        tint: DJToken.accent(forAppID: summary.archive.sourceAppID)
                                    )
                                    .frame(height: 36)
                                    Text(summary.context.eventName.isEmpty ? summary.archive.originalFilename : summary.context.eventName)
                                        .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                                        .foregroundStyle(DJToken.foreground)
                                        .lineLimit(1)
                                    Text([summary.context.venue, summary.context.city].filter { !$0.isEmpty }.joined(separator: ", "))
                                        .font(.system(size: DJToken.TypeSize.secondary))
                                        .foregroundStyle(DJToken.mutedForeground)
                                        .lineLimit(1)
                                    Rectangle().fill(DJToken.hairline).frame(height: 1)
                                    HStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: DJToken.Radius.swatch)
                                            .fill(DJToken.accent(forAppID: summary.archive.sourceAppID))
                                            .frame(width: 3, height: 10)
                                        Text(model.displayName(for: summary.archive.sourceAppID))
                                            .font(.system(size: DJToken.TypeSize.secondary))
                                            .foregroundStyle(DJToken.mutedForeground)
                                        Spacer()
                                        Text(HomeFormatting.formatDuration(summary.archive.durationSeconds))
                                            .font(.system(size: DJToken.TypeSize.secondary).monospacedDigit())
                                            .foregroundStyle(DJToken.mutedForeground)
                                    }
                                }
                                .padding(10)
                                .frame(width: 196, alignment: .leading)
                                .background(DJToken.elevated, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
                                .overlay(
                                    RoundedRectangle(cornerRadius: DJToken.Radius.control)
                                        .stroke(DJToken.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
