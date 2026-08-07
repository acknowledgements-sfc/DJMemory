import SwiftUI

struct Panel<HeaderActions: View, Content: View>: View {
    var title: String?
    var tone: StatusTone = .neutral
    var padding: CGFloat = 0
    @ViewBuilder var headerActions: () -> HeaderActions
    @ViewBuilder var content: () -> Content

    init(
        title: String? = nil,
        tone: StatusTone = .neutral,
        padding: CGFloat = 0,
        @ViewBuilder headerActions: @escaping () -> HeaderActions = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.tone = tone
        self.padding = padding
        self.headerActions = headerActions
        self.content = content
    }

    private var borderColor: Color {
        switch tone {
        case .ok:
            return DJToken.ok.opacity(0.4)
        case .warn:
            return DJToken.warn.opacity(0.45)
        case .danger:
            return DJToken.danger.opacity(0.45)
        case .info:
            return DJToken.primary.opacity(0.4)
        case .neutral:
            return DJToken.border
        }
    }

    private var showsHeader: Bool {
        title != nil || !(HeaderActions.self == EmptyView.self)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showsHeader {
                HStack(spacing: 12) {
                    if let title {
                        Text(title)
                            .microLabelStyle()
                    }
                    Spacer(minLength: 0)
                    headerActions()
                }
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(DJToken.muted.opacity(0.6))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(DJToken.hairline)
                        .frame(height: 1)
                }
            }

            content()
                .padding(padding)
        }
        .background(DJToken.card, in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: DJToken.Radius.control)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

#Preview("Panel tones") {
    VStack(spacing: 12) {
        Panel(title: "Default", padding: 12) {
            Text("Body").font(.system(size: DJToken.TypeSize.body))
        }
        Panel(title: "Warn", tone: .warn, padding: 12) {
            Text("Attention").font(.system(size: DJToken.TypeSize.body))
        }
        Panel(title: "Danger", tone: .danger, padding: 12) {
            Text("Broken folder").font(.system(size: DJToken.TypeSize.body))
        }
    }
    .padding()
    .frame(width: 360)
    .background(DJToken.content)
}
