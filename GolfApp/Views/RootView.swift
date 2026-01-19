import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Theme.background.ignoresSafeArea()
                Group {
                    if appState.currentUser == nil {
                        AuthFlowView()
                    } else {
                        MainMenuView()
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .tint(Theme.accent)
        .task {
            await appState.loadExistingSession()
        }
        .onChange(of: appState.currentUser) { oldValue, newValue in
            // Reset navigation stack when user logs out
            if newValue == nil && oldValue != nil {
                navigationPath = NavigationPath()
            }
        }
    }
}

// Main menu placeholder stays until the real menu is added

// Placeholder removed once full menu is added

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView().environmentObject(AppState())
    }
}


