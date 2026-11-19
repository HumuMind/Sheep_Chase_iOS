import SheepChaseRunShellFeature
import SheepChaseUI
import SwiftData
import SwiftUI

@main
@MainActor
struct SheepChaseApp: App {
    private let startup: Result<AppStartup.Ready, StartupFailure> = AppStartup.make()

    var body: some Scene {
        WindowGroup("荒野逐羊") {
            switch startup {
            case .success(let ready):
                RootView()
                    .environment(ready.store)
                    .frame(minWidth: 1040, minHeight: 700)
                    .modelContainer(ready.container)
            case .failure(let failure):
                StartupErrorView(message: failure.message)
                    .frame(minWidth: 520, minHeight: 360)
            }
        }
        .commands {
            RunShortcutCommands()
        }
        #if os(macOS)
        .defaultSize(width: 1380, height: 900)
        #endif
    }
}
