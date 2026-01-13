import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var userStats: UserStatsResponse?
    @State private var isLoadingStats = false

    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                HStack(spacing: 12) {
                    // Avatar
                    if let avatarUrl = appState.currentUser?.avatarUrl,
                       let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(.white)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 56, height: 56)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.currentUser?.username ?? "")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let email = appState.currentUser?.email {
                            Text(email)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .listRowBackground(Theme.card.opacity(0.85))
            }
            
            Section(header: Text("Stats")) {
                if isLoadingStats {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    }
                    .listRowBackground(Theme.card.opacity(0.85))
                } else {
                    StatRow(
                        icon: "trophy.fill",
                        label: "Global Score",
                        value: "\(appState.currentUser?.globalScore ?? 0)"
                    )
                    
                    if let ranking = appState.currentUser?.ranking {
                        StatRow(
                            icon: "chart.bar.fill",
                            label: "Global Rank",
                            value: "#\(ranking)"
                        )
                    }
                    
                    StatRow(
                        icon: "creditcard.fill",
                        label: "Coins",
                        value: "\(appState.coins)"
                    )
                    
                    if let stats = userStats {
                        StatRow(
                            icon: "flag.fill",
                            label: "Levels Completed",
                            value: "\(stats.levelsCompleted)"
                        )
                        
                        StatRow(
                            icon: "star.fill",
                            label: "Total Stars",
                            value: "\(stats.totalStars)"
                        )
                    }
                    
                    // Equipped skin
                    StatRow(
                        icon: "circle.fill",
                        label: "Equipped Skin",
                        value: appState.equippedSkinId.capitalized
                    )
                }
            }
            .listRowBackground(Theme.card.opacity(0.85))

            Section(header: Text("Audio")) {
                Toggle("Music", isOn: $appState.musicEnabled)
                Toggle("Sound effects", isOn: $appState.soundEffectsEnabled)
            }
            .tint(Theme.accent)
            .listRowBackground(Theme.card.opacity(0.85))

            Section {
                Button(role: .destructive) { appState.logout() } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            .listRowBackground(Theme.card.opacity(0.85))
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Settings")
        .task {
            await loadStats()
        }
    }
    
    private func loadStats() async {
        isLoadingStats = true
        userStats = await appState.getUserStats()
        isLoadingStats = false
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.accent)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .foregroundColor(.white.opacity(0.8))
                .fontWeight(.medium)
        }
    }
}
