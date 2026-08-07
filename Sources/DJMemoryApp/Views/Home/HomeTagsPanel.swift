import SwiftUI
import DJMemoryCore

struct HomeTagsPanel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Panel(title: "Your tags", padding: 12) {
            Text("From set details you wrote.")
                .font(.system(size: DJToken.TypeSize.secondary))
                .foregroundStyle(DJToken.mutedForeground)
            if model.tagCounts.isEmpty {
                Text("No tags yet.")
                    .font(.system(size: DJToken.TypeSize.secondary))
                    .foregroundStyle(DJToken.mutedForeground)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.tagCounts.prefix(12), id: \.display) { tag in
                        Badge(title: "\(tag.display) · \(tag.count)", tone: .neutral)
                    }
                }
            }
        }
    }
}
