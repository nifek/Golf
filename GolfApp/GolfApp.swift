import SwiftUI
import FirebaseCore

@main
struct GolfApp: App {
    init() {
        FirebaseApp.configure()
    }

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}


