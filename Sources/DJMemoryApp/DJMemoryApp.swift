import SwiftUI
import DJMemoryCore

@main
struct DJMemoryApplication: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("DJMemory") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 980, minHeight: 640)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarStatusView()
                .environmentObject(model)
        } label: {
            Image(systemName: model.protectionSymbolName)
        }
    }
}
