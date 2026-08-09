import ClerkKit
import ClerkKitUI
import SwiftUI

/// Optional Clerk account controls for Settings. Local protection never depends on sign-in.
struct SettingsAccountPanel: View {
    @EnvironmentObject private var model: AppModel
    @Environment(Clerk.self) private var clerk
    @Environment(\.openURL) private var openURL
    @State private var authIsPresented = false

    var body: some View {
        Panel(title: "Account", padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Local protection never depends on an account.")
                    .font(.system(size: DJToken.TypeSize.body, weight: .medium))
                Text("Audio files are never uploaded by default.")
                    .font(.system(size: DJToken.TypeSize.body))
                    .foregroundStyle(DJToken.mutedForeground)
                Text("Full tracklists stay on this Mac unless you explicitly export them.")
                    .font(.system(size: DJToken.TypeSize.body))
                    .foregroundStyle(DJToken.mutedForeground)
                Text("Diagnostics exports contain metadata only — paths, timings, counts, and error strings.")
                    .font(.system(size: DJToken.TypeSize.body))
                    .foregroundStyle(DJToken.mutedForeground)

                UserButton(signedOutContent: {
                    Button {
                        authIsPresented = true
                    } label: {
                        Label("Sign in", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .buttonStyle(DJSecondaryButtonStyle())
                    .accessibilityIdentifier("settings.signIn")
                })
                .padding(.top, 6)

                Button {
                    model.showOnboardingAgain()
                } label: {
                    Label("Show First-Run Setup", systemImage: "sparkles.rectangle.stack")
                }
                .buttonStyle(DJSecondaryButtonStyle())
                .accessibilityIdentifier("settings.showOnboarding")

                Button {
                    if let url = URL(string: Self.accountURLString) {
                        openURL(url)
                    }
                } label: {
                    Label("Open Account in Browser", systemImage: "person.crop.circle")
                }
                .buttonStyle(DJGhostButtonStyle())
                .accessibilityIdentifier("settings.openAccount")
            }
        }
        .sheet(isPresented: $authIsPresented) {
            AuthView()
        }
        .onChange(of: clerk.user?.id) { _, userID in
            if userID != nil {
                authIsPresented = false
            }
        }
    }

    /// Optional web accounts host. Local protection never depends on this URL being reachable.
    private static let accountURLString =
        ProcessInfo.processInfo.environment["DJMEMORY_ACCOUNT_URL"]
        ?? "https://accounts.djmemory.app"
}

#Preview("Signed out") {
    SettingsAccountPanel()
        .environmentObject(AppModel())
        .environment(Clerk.preview { preview in
            preview.isSignedIn = false
        })
        .padding()
        .frame(width: 420)
}

#Preview("Signed in") {
    SettingsAccountPanel()
        .environmentObject(AppModel())
        .environment(Clerk.preview())
        .padding()
        .frame(width: 420)
}
