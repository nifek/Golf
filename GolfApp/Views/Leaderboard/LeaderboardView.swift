import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        List {
            ForEach(appState.leaderboard) { entry in
                HStack(spacing: 12) {
                    Text("\(entry.rank)")
                        .font(.headline)
                        .frame(width: 28)
                        .foregroundColor(.white.opacity(0.9))
                    Image(systemName: entry.avatarSystemName)
                        .foregroundColor(.white)
                    Text(entry.username)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(entry.score)")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                .listRowBackground(Theme.card.opacity(0.85))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Leaderboard")
    }
}


