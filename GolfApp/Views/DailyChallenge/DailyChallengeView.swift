import SwiftUI

struct DailyChallengeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: ChallengeTab = .play
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            Picker("Tab", selection: $selectedTab) {
                Text("Play").tag(ChallengeTab.play)
                Text("My Attempts").tag(ChallengeTab.attempts)
                Text("Leaderboard").tag(ChallengeTab.leaderboard)
            }
            .pickerStyle(.segmented)
            .padding()
            
            switch selectedTab {
            case .play:
                ChallengePlayTab()
            case .attempts:
                MyAttemptsTab()
            case .leaderboard:
                ChallengeLeaderboardTab()
            }
        }
        .background(Theme.background)
        .navigationTitle("Daily Challenge")
        .task {
            await appState.loadTodayChallenge()
        }
    }
}

private enum ChallengeTab {
    case play
    case attempts
    case leaderboard
}

// MARK: - Play Tab

private struct ChallengePlayTab: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        if appState.isLoadingChallenge {
            Spacer()
            ProgressView()
                .tint(.white)
            Spacer()
        } else if let challenge = appState.todayChallenge {
            ScrollView {
                VStack(spacing: 24) {
                    // Challenge info card
                    VStack(spacing: 16) {
                        Text(challenge.title ?? "Today's Challenge")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        
                        if let description = challenge.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        // Stats
                        HStack(spacing: 32) {
                            StatItem(
                                icon: "person.2.fill",
                                value: "\(challenge.totalParticipants)",
                                label: "Players"
                            )
                            
                            StatItem(
                                icon: "flag.fill",
                                value: "\(challenge.userAttempts)",
                                label: "Your Attempts"
                            )
                            
                            if let stars = challenge.userBestStars {
                                StatItem(
                                    icon: "star.fill",
                                    value: "\(stars)",
                                    label: "Best Stars"
                                )
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.card.opacity(0.8))
                    )
                    
                    // Play button
                    NavigationLink(destination: DailyChallengePlayView(challenge: challenge)) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text(challenge.userAttempts > 0 ? "Play Again" : "Play Now")
                        }
                    }
                    .buttonStyle(FilledButtonStyle())
                    .frame(maxWidth: 250)
                    
                    // Reward tiers info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rewards")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        RewardRow(rank: "1st", coins: 1000)
                        RewardRow(rank: "2nd", coins: 750)
                        RewardRow(rank: "3rd", coins: 500)
                        RewardRow(rank: "4th", coins: 300)
                        RewardRow(rank: "5th", coins: 200)
                        RewardRow(rank: "6-10th", coins: 150)
                        RewardRow(rank: "11th+", coins: 50)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Theme.surface.opacity(0.6))
                    )
                }
                .padding()
            }
        } else {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.5))
                Text("No challenge available today")
                    .foregroundColor(.white.opacity(0.7))
                Text("Check back tomorrow!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.accent)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

private struct RewardRow: View {
    let rank: String
    let coins: Int
    
    var body: some View {
        HStack {
            Text(rank)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                Text("\(coins)")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(Theme.gold)
        }
    }
}

// MARK: - My Attempts Tab

private struct MyAttemptsTab: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if appState.myAttempts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "flag.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.5))
                    Text("No attempts yet")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Play the challenge to see your attempts here")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(appState.myAttempts.enumerated()), id: \.element.id) { index, attempt in
                        AttemptRow(attempt: attempt, index: index + 1)
                            .listRowBackground(Theme.card.opacity(0.8))
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .task {
            await appState.loadMyAttempts()
        }
    }
}

private struct AttemptRow: View {
    let attempt: DailyChallengeAttemptResponse
    let index: Int
    
    private var formattedTime: String {
        let seconds = Double(attempt.timeToPassMs) / 1000.0
        if seconds < 60 {
            return String(format: "%.2fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = seconds.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%05.2f", minutes, remainingSeconds)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(index)")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < attempt.stars ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(Theme.gold)
                    }
                }
                
                HStack(spacing: 8) {
                    Text("\(attempt.strokes) strokes")
                        .font(.caption)
                    Text("•")
                    Text(formattedTime)
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("\(attempt.score)")
                .font(.title3.weight(.bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Leaderboard Tab

private struct ChallengeLeaderboardTab: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Group {
            if appState.isLoadingLeaderboard {
                ProgressView()
                    .tint(.white)
                    .frame(maxHeight: .infinity)
            } else if appState.leaderboard.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.5))
                    Text("No entries yet")
                        .foregroundColor(.white.opacity(0.7))
                    Text("Be the first to compete!")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(appState.leaderboard) { entry in
                        ChallengeLeaderboardRow(
                            entry: entry,
                            isCurrentUser: entry.userId == appState.currentUser?.id
                        )
                        .listRowBackground(
                            entry.userId == appState.currentUser?.id
                                ? Theme.accent.opacity(0.3)
                                : Theme.card.opacity(0.8)
                        )
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .task {
            await appState.loadLeaderboard()
        }
    }
}

private struct ChallengeLeaderboardRow: View {
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
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(entry.rank)")
                .font(.headline)
                .foregroundColor(rankColor)
                .frame(width: 32)
            
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

// MARK: - Daily Challenge Play View (Placeholder for actual gameplay)

struct DailyChallengePlayView: View {
    let challenge: DailyChallenge
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var isPlaying = false
    @State private var isSubmitting = false
    @State private var result: DailyChallengeAttemptResponse?
    
    // Demo values (in real implementation, these come from GameScene)
    @State private var demoStrokes = 5
    @State private var demoStars = 2
    @State private var startTime: Date?
    
    var body: some View {
        VStack(spacing: 24) {
            if let result = result {
                // Result view
                VStack(spacing: 20) {
                    Text("Challenge Complete!")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { idx in
                            Image(systemName: idx < result.stars ? "star.fill" : "star")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.gold)
                        }
                    }
                    
                    Text("Score: \(result.score)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        Text("\(result.strokes) strokes")
                        Text(formatTime(result.timeToPassMs))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    
                    Button("Back to Challenge") {
                        dismiss()
                    }
                    .buttonStyle(FilledButtonStyle())
                }
            } else if isSubmitting {
                ProgressView()
                    .tint(.white)
                Text("Submitting...")
                    .foregroundColor(.white.opacity(0.7))
            } else {
                // Demo play controls
                Text(challenge.title ?? "Daily Challenge")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                
                Text("Demo Mode - Adjust values and submit")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                VStack(spacing: 16) {
                    Stepper("Strokes: \(demoStrokes)", value: $demoStrokes, in: 1...20)
                        .foregroundColor(.white)
                    
                    Stepper("Stars: \(demoStars)", value: $demoStars, in: 1...3)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Theme.card.opacity(0.8))
                .cornerRadius(12)
                
                Button("Submit Attempt") {
                    Task {
                        await submitAttempt()
                    }
                }
                .buttonStyle(FilledButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            startTime = Date()
        }
    }
    
    private func submitAttempt() async {
        guard let start = startTime else { return }
        
        isSubmitting = true
        let timeMs = Int(Date().timeIntervalSince(start) * 1000)
        
        result = await appState.completeDailyChallenge(
            timeToPassMs: timeMs,
            strokes: demoStrokes,
            stars: demoStars
        )
        
        isSubmitting = false
    }
    
    private func formatTime(_ ms: Int) -> String {
        let seconds = Double(ms) / 1000.0
        if seconds < 60 {
            return String(format: "%.2fs", seconds)
        } else {
            let minutes = Int(seconds) / 60
            let remainingSeconds = seconds.truncatingRemainder(dividingBy: 60)
            return String(format: "%d:%05.2f", minutes, remainingSeconds)
        }
    }
}
