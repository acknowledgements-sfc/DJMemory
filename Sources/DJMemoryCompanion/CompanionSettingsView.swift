import ClerkKit
import ClerkKitUI
import SwiftUI

struct CompanionSettingsView: View {
    @Bindable var model: CompanionModel
    @Environment(Clerk.self) private var clerk
    @State private var authPresented = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy") {
                    Text("Local library and import never depend on an account.")
                    Text("Audio files are never uploaded by default.")
                    Text("Full tracklists stay on this iPad unless you explicitly export them.")
                }

                Section("Account") {
                    UserButton(signedOutContent: {
                        Button("Sign in") { authPresented = true }
                            .accessibilityIdentifier("ipad.settings.signIn")
                    })

                    if clerk.user != nil {
                        if let summary = model.accountLicenseSummary {
                            LabeledContent("License", value: summary)
                                .accessibilityIdentifier("ipad.settings.accountLicense")
                        }
                        if let message = model.accountSyncMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Button("Refresh Account") {
                            Task { await sync() }
                        }
                        .accessibilityIdentifier("ipad.settings.refreshAccount")
                    }
                }

                Section("Archive") {
                    Text(model.archiveRoot.path)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        .accessibilityIdentifier("ipad.settings.archivePath")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $authPresented) {
                AuthView()
            }
            .onChange(of: clerk.user?.id) { _, userID in
                if userID != nil {
                    authPresented = false
                    Task { await sync() }
                } else {
                    Task { await model.syncAccount(bearerToken: nil) }
                }
            }
            .task(id: clerk.user?.id) {
                if clerk.user != nil { await sync() }
            }
        }
    }

    private func sync() async {
        let token = try? await clerk.session?.getToken()
        await model.syncAccount(bearerToken: token)
    }
}
