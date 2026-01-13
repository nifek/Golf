import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: LeaderboardTab = .daily

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Leaderboard Type", selection: $selectedTab) {
                Text("Daily").tag(LeaderboardTab.daily)
                Text("Global").tag(LeaderboardTab.global)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if appState.isLoadingLeaderboard {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else if appState.leaderboard.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.5))
                    Text("No entries yet")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Be the first to compete!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
            } else {
                List {
                    ForEach(appState.leaderboard) { entry in
                        LeaderboardRow(
                            entry: entry,
                            isCurrentUser: entry.userId == appState.currentUser?.id
                        )
                        .listRowBackground(
                            entry.userId == appState.currentUser?.id
                                ? Theme.accent.opacity(0.3)
                                : Theme.card.opacity(0.85)
                        )
                    }
                }
                .scrollContentBackground(.hidden)
            }
            
            // Current user position if not in visible list
            if let myPosition = appState.getMyLeaderboardPosition(),
               myPosition.rank > 10 {
                Divider()
                    .background(Color.white.opacity(0.3))
                LeaderboardRow(entry: myPosition, isCurrentUser: true)
                    .padding()
                    .background(Theme.accent.opacity(0.3))
            }
        }
        .background(Theme.background)
        .navigationTitle("Leaderboard")
        .task {
            await loadLeaderboard()
        }
        .refreshable {
            await loadLeaderboard()
        }
    }
    
    private func loadLeaderboard() async {
        switch selectedTab {
        case .daily:
            await appState.loadLeaderboard()
        case .global:
            // TODO: Implement global leaderboard when API is available
            await appState.loadLeaderboard()
        }
    }
}

private enum LeaderboardTab {
    case daily
    case global
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let isCurrentUser: Bool
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color.yellow
        case 2: return Color.gray
        case 3: return Color.orange
        default: return Color.white.opacity(0.9)
        }
    }
    
    private var rankIcon: String? {
        switch entry.rank {
        case 1: return "crown.fill"
        case 2, 3: return "medal.fill"
        default: return nil
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                if let icon = rankIcon {
                    Image(systemName: icon)
                        .foregroundColor(rankColor)
                        .font(.title3)
                } else {
                    Text("\(entry.rank)")
                        .font(.headline)
                        .foregroundColor(rankColor)
                }
            }
            .frame(width: 32)
            
            // Avatar
            if let avatarUrl = entry.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.white)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Username
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.username)
                    .font(.body.weight(isCurrentUser ? .bold : .regular))
                    .foregroundColor(.white)
                
                if let stars = entry.stars {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { idx in
                            Image(systemName: idx < stars ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(Theme.gold)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Score and reward
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let reward = entry.coinsReward, reward > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "creditcard.fill")
                            .font(.caption2)
                        Text("+\(reward)")
                            .font(.caption2)
                    }
                    .foregroundColor(Theme.gold)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
