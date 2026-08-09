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
struct DJMemoryApplication: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    init() {
        // Optional Account auth only — local archive/scan/protection never depend on Clerk.
        Clerk.configure(publishableKey: "pk_test_Z2xvcmlvdXMtbG9uZ2hvcm4tMzYuY2xlcmsuYWNjb3VudHMuZGV2JA")
    }

    var body: some Scene {
        WindowGroup("DJMemory") {
            ContentView()
                .environmentObject(model)
                .environment(Clerk.shared)
                .prefetchClerkImages()
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
