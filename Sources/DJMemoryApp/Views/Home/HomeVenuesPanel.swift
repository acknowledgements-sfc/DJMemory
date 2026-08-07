import SwiftUI
import DJMemoryCore

struct HomeVenuesPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Panel(title: "Where you play most", padding: 12) {
            if model.venueCounts.isEmpty {
                Text("Add venues in set details to see them here.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.mutedForeground)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                    ForEach(model.venueCounts, id: \.name) { venue in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(venue.name).font(.system(size: DJToken.TypeSize.body, weight: .medium))
                            Text(venue.city).font(.system(size: DJToken.TypeSize.secondary)).foregroundStyle(DJToken.mutedForeground)
                            Text("\(venue.setCount) sets").font(.system(size: DJToken.TypeSize.secondary).monospacedDigit()).foregroundStyle(DJToken.mutedForeground)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DJToken.muted, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
                    }
                }
            }
        }
    }
}
