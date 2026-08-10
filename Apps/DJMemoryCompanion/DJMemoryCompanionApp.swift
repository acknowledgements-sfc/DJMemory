import ClerkKit
import ClerkKitUI
import SwiftUI
import DJMemoryCompanion

@main
struct DJMemoryCompanionApp: App {
    @State private var model = CompanionModel()

    /// Stable identity for OAuth redirects / keychain. Matches Info.plist + Clerk Native Application.
    private static let appBundleID = "app.djmemory.DJMemory.iPad"
    private static let oauthCallbackURL = "\(appBundleID)://callback"

    init() {
        // Optional Account auth only — local library/import never depend on Clerk.
        Clerk.configure(
            publishableKey: "pk_test_Z2xvcmlvdXMtbG9uZ2hvcm4tMzYuY2xlcmsuYWNjb3VudHMuZGV2JA",
            options: .init(
                keychainConfig: .init(service: Self.appBundleID),
                redirectConfig: .init(
                    redirectUrl: Self.oauthCallbackURL,
                    callbackUrlScheme: Self.appBundleID
                )
            )
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
                .onOpenURL { url in
                    Task {
                        do {
                            try await Clerk.shared.handle(url)
                        } catch {
                            // Deep-link auth failures must not block local library/import.
                        }
                        CompanionInbox.drain(into: model)
                    }
                }
        }
    }
}
