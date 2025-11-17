import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                HStack {
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        HStack(spacing: 8) {
                            Text(appState.currentUser?.username ?? "")
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                        .padding(10)
                        .background(Capsule().fill(Theme.surface.opacity(0.9)))
                    }
                }

                LogoView()
                    .padding(.top, 32)

                NavigationLink(destination: LevelsView()) {
                    Text("Play")
                }
                .buttonStyle(FilledButtonStyle())

                NavigationLink(destination: DailyChallengeView()) {
                    Text("Daily Challenge")
                }
                .buttonStyle(FilledButtonStyle(color: Theme.surface))

                NavigationLink(destination: ShopView()) {
                    Text("Shop")
                }
                .buttonStyle(FilledButtonStyle(color: Theme.surface))

                NavigationLink(destination: LeaderboardView()) {
                    Text("Leaderboard")
                }
                .buttonStyle(FilledButtonStyle(color: Theme.surface))

                NavigationLink(destination: TutorialView()) {
                    Text("Tutorial")
                }
                .buttonStyle(FilledButtonStyle(color: Theme.surface))

                Spacer(minLength: 20)
            }
            .padding(.vertical, 24)
        }
        .navigationBarBackButtonHidden(true)
        .background(Theme.background)
    }
}

private struct DailyChallengeView: View { var body: some View { PlaceholderScreen(title: "Daily Challenge") } }
private struct TutorialView: View { var body: some View { PlaceholderScreen(title: "Tutorial") } }

private struct PlaceholderScreen: View {
    let title: String
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(Theme.accent)
            Text("Coming soon")
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
}


