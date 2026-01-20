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
            if newValue == nil && oldValue != nil {
                navigationPath = NavigationPath()
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView().environmentObject(AppState())
    }
}


