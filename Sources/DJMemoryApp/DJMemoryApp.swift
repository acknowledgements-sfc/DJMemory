import AppKit
import ClerkKit
import ClerkKitUI
import SwiftUI
import DJMemoryCore
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if LocalNotificationService.canUseUserNotifications {
            UNUserNotificationCenter.current().delegate = self
        }

        // Menu-bar-only launches skip the Dock/activation entirely — the app stays
        // an accessory until the user explicitly opens the main window.
        let menuBarOnly = (try? AppSettingsStore().load())?.menuBarOnly ?? true
        guard !menuBarOnly else {
            NSApp.setActivationPolicy(.accessory)
            // SwiftUI's WindowGroup still opens a window on launch; close it so the
            // app truly starts in the menu bar only, until the user asks for it.
            DispatchQueue.main.async {
                NSApp.windows.forEach { $0.close() }
            }
            return
        }

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.async {
            NSApp.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@main
enum DJMemoryMain {
    static func main() {
        #if os(macOS)
        let args = Array(CommandLine.arguments.dropFirst())
        if args.first == "--app-audio-probe" {
            let parsed = AppAudioProbeRunner.parseArgs(Array(args.dropFirst()))
            AppAudioProbeRunner.run(softwareID: parsed.softwareID, seconds: parsed.seconds)
            return
        }
        #endif
        DJMemoryApplication.main()
    }
}

struct DJMemoryApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    /// Stable identity for OAuth redirects / keychain. `swift run` has no Info.plist bundle id.
    private static let appBundleID = "app.djmemory.DJMemory"
    private static let oauthCallbackURL = "\(appBundleID)://callback"
    private static let clerkPublishableKey = DJMemoryAccountConfiguration.clerkPublishableKey
    private static var isAccountAuthEnabled: Bool { clerkPublishableKey != nil }

    init() {
        // Optional Account auth only — local archive/scan/protection never depend on Clerk.
        if let publishableKey = Self.clerkPublishableKey {
            Clerk.configure(
                publishableKey: publishableKey,
                options: .init(
                    keychainConfig: .init(service: Self.appBundleID),
                    redirectConfig: .init(
                        redirectUrl: Self.oauthCallbackURL,
                        callbackUrlScheme: Self.appBundleID
                    )
                )
            )
        }
    }

    var body: some Scene {
        WindowGroup("DJMemory") {
            rootView
                .frame(minWidth: 980, minHeight: 640)
        }
        .commands {
            AppCommands(model: model)
        }

        MenuBarExtra {
            menuBarView
        } label: {
            MenuBarIconView(state: model.menuBarState)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if Self.isAccountAuthEnabled {
            ContentView(isAccountAuthEnabled: true)
                .environmentObject(model)
                // Prefetch reads @Environment(Clerk.self) — must be inside .environment(Clerk.shared).
                .prefetchClerkImages()
                .environment(Clerk.shared)
        } else {
            ContentView(isAccountAuthEnabled: false)
                .environmentObject(model)
        }
    }

    @ViewBuilder
    private var menuBarView: some View {
        if Self.isAccountAuthEnabled {
            MenuBarStatusView()
                .environmentObject(model)
                .environment(Clerk.shared)
        } else {
            MenuBarStatusView()
                .environmentObject(model)
        }
    }
}
