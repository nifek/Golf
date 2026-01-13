import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                // Top bar with user info and coins
                HStack {
                    // Coins display
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard.circle.fill")
                            .foregroundColor(Theme.gold)
                        Text("\(appState.coins)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.surface.opacity(0.9)))
                    
                    Spacer()
                    
                    // User profile
                    NavigationLink(destination: SettingsView()) {
                        HStack(spacing: 8) {
                            Text(appState.currentUser?.username ?? "")
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            if let avatarUrl = appState.currentUser?.avatarUrl,
                               let url = URL(string: avatarUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.crop.circle.fill")
                                        .foregroundColor(.white)
                                }
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .foregroundColor(.white)
                                    .imageScale(.large)
                            }
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
                    HStack {
                        Text("Daily Challenge")
                        if appState.todayChallenge != nil {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 8, height: 8)
                        }
                    }
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
        .task {
            // Preload today's challenge to show indicator
            await appState.loadTodayChallenge()
        }
    }
}

private struct TutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("How to Play")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.accent)
                
                TutorialStep(
                    number: 1,
                    title: "Aim",
                    description: "Tap and hold near the ball, then drag in the opposite direction you want to hit.",
                    icon: "hand.tap"
                )
                
                TutorialStep(
                    number: 2,
                    title: "Shoot",
                    description: "Release to hit the ball. The further you drag, the harder you hit.",
                    icon: "arrow.up.right.circle"
                )
                
                TutorialStep(
                    number: 3,
                    title: "Score",
                    description: "Get the ball in the hole with as few strokes as possible to earn more stars.",
                    icon: "star.fill"
                )
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text("Star Ratings")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    StarInfo(stars: 3, description: "Complete under par")
                    StarInfo(stars: 2, description: "Complete at or near par")
                    StarInfo(stars: 1, description: "Complete the level")
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text("Daily Challenges")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text("Compete daily against other players! Top performers earn coins that can be spent in the shop on cosmetic skins for your golf ball.")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Tutorial")
    }
}

private struct TutorialStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Step \(number): \(title)")
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

private struct StarInfo: View {
    let stars: Int
    let description: String
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { idx in
                    Image(systemName: idx < stars ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundColor(Theme.gold)
                }
            }
            .frame(width: 60)
            
            Text(description)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
