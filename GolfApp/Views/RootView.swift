import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
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
    }
}

// Main menu placeholder stays until the real menu is added

// Placeholder removed once full menu is added

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView().environmentObject(AppState())
    }
}


