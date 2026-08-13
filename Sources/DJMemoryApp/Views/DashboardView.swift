import SwiftUI
import DJMemoryCore

struct DashboardView: View {
    @EnvironmentObject private var model: AppModel
    let isAccountAuthEnabled: Bool

    init(isAccountAuthEnabled: Bool = false) {
        self.isAccountAuthEnabled = isAccountAuthEnabled
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView()

                switch model.selectedRoute {
                case .home:
                    HomeDashboardView()
                case .protection:
                    ProtectionDashboardView()
                case .capture:
                    CaptureView()
                case .library:
                    SessionLibraryView()
                case .activity:
                    ActivityLogView()
                case .settings:
                    SettingsView(isAccountAuthEnabled: isAccountAuthEnabled)
                case .app:
                    AdapterDetailView()
                case .recovery(let appID):
                    RecoveryView(appID: appID)
                }
            }
            .padding(28)
        }
        .background(DJToken.content)
    }
}
