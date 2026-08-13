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

    init() {
        // Optional Account auth only — local archive/scan/protection never depend on Clerk.
        if let publishableKey = DJMemoryAccountConfiguration.clerkPublishableKey {
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
            ContentView()
                .environmentObject(model)
                // Prefetch reads @Environment(Clerk.self) — must be inside .environment(Clerk.shared).
                .prefetchClerkImages()
                .environment(Clerk.shared)
                .frame(minWidth: 980, minHeight: 640)
        }
        .commands {
            AppCommands(model: model)
        }

        MenuBarExtra {
            MenuBarStatusView()
                .environmentObject(model)
                .environment(Clerk.shared)
        } label: {
            Image(systemName: model.protectionSymbolName)
        }
    }
}
