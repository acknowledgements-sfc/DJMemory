import SwiftUI
import DJMemoryCore

struct HomeTopTracksPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Panel(title: "Your most played tracks", padding: 0) {
            if model.topTracks.isEmpty {
                Text("Import a set history to see top tracks.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.mutedForeground)
                    .padding(12)
            } else {
                let maxPlays = max(model.topTracks.first?.playCount ?? 1, 1)
                ForEach(Array(model.topTracks.enumerated()), id: \.offset) { index, track in
                    HStack(spacing: 10) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: DJToken.TypeSize.secondary, design: .monospaced))
                            .foregroundStyle(DJToken.mutedForeground)
                            .frame(width: 24, alignment: .leading)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(track.title.isEmpty ? "Unknown title" : track.title)
                                .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                            Text(track.artist.isEmpty ? "Unknown artist" : track.artist)
                                .font(.system(size: DJToken.TypeSize.secondary))
                                .foregroundStyle(DJToken.mutedForeground)
                        }
                        Spacer()
                        Text(track.lastEventName)
                            .font(.system(size: DJToken.TypeSize.secondary))
                            .foregroundStyle(DJToken.mutedForeground)
                            .lineLimit(1)
                        ZStack(alignment: .leading) {
                            Rectangle().fill(DJToken.secondary).frame(width: 48, height: 1)
                            Rectangle().fill(DJToken.primary).frame(width: 48 * CGFloat(track.playCount) / CGFloat(maxPlays), height: 1)
                        }
                        Text("\(track.playCount)")
                            .font(.system(size: DJToken.TypeSize.secondary).monospacedDigit())
                            .frame(width: 24, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    if index < model.topTracks.count - 1 {
                        Rectangle().fill(DJToken.hairline).frame(height: 1)
                    }
                }
            }
        }
    }
}
