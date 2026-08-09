import ClerkKit
import ClerkKitUI
import SwiftUI
import DJMemoryCompanion

@main
struct DJMemoryCompanionApp: App {
    @State private var model = CompanionModel()

    init() {
        // Optional Account auth only — local library/import never depend on Clerk.
        Clerk.configure(
            publishableKey: "pk_test_Z2xvcmlvdXMtbG9uZ2hvcm4tMzYuY2xlcmsuYWNjb3VudHMuZGV2JA"
        )
    }

    var body: some Scene {
        WindowGroup {
            CompanionRootView(model: model)
                .environment(Clerk.shared)
                .prefetchClerkImages()
                .onAppear {
                    CompanionInbox.drain(into: model)
                }
                .onOpenURL { _ in
                    CompanionInbox.drain(into: model)
                }
        }
    }
}
