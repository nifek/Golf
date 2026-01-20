import SwiftUI
import SpriteKit

struct DailyChallengeView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var challenge: DailyChallengeResponse?
    @State private var leaderboard: [DailyChallengeLeaderboardEntry] = []
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var selectedTab: ChallengeTab = .play
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if let challenge = challenge {
                Picker("Tab", selection: $selectedTab) {
                    Text("Play").tag(ChallengeTab.play)
                    Text("Leaderboard").tag(ChallengeTab.leaderboard)
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedTab {
                case .play:
                    PlayTab(challenge: challenge)
                case .leaderboard:
                    LeaderboardTab(leaderboard: leaderboard, currentUserId: appState.currentUser?.id)
                }
            } else {
                noChallengeView
            }
        }
        .background(Theme.background)
        .navigationTitle("Daily Challenge")
        .task {
            await loadChallenge()
        }
        .refreshable {
            await loadChallenge()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            Text("Loading challenge...")
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
                .foregroundColor(.white)
            Text(error)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await loadChallenge() }
            }
            .buttonStyle(FilledButtonStyle())
            .frame(width: 150)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noChallengeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            Text("No Challenge Today")
                .font(.headline)
                .foregroundColor(.white)
            Text("Check back tomorrow!")
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadChallenge() async {
        isLoading = true
        loadError = nil
        
        do {
            challenge = try await DailyChallengeService.shared.getTodayChallenge()
            leaderboard = try await DailyChallengeService.shared.getLeaderboard()
        } catch {
            loadError = error.localizedDescription
        }
        
        isLoading = false
    }
}

private enum ChallengeTab {
    case play
    case leaderboard
}

private struct PlayTab: View {
    let challenge: DailyChallengeResponse
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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
                
                NavigationLink(destination: DailyChallengePlayView(challenge: challenge)) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(challenge.userAttempts > 0 ? "Play Again" : "Play Now")
                    }
                }
                .buttonStyle(FilledButtonStyle())
                .frame(maxWidth: 250)
                
                RewardTiersCard()
            }
            .padding()
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

private struct RewardTiersCard: View {
    var body: some View {
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

private struct LeaderboardTab: View {
    let leaderboard: [DailyChallengeLeaderboardEntry]
    let currentUserId: Int?
    
    var body: some View {
        if leaderboard.isEmpty {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(leaderboard) { entry in
                    LeaderboardRow(entry: entry, isCurrentUser: entry.userId == currentUserId)
                        .listRowBackground(
                            entry.userId == currentUserId
                                ? Theme.accent.opacity(0.3)
                                : Theme.card.opacity(0.8)
                        )
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

private struct LeaderboardRow: View {
    let entry: DailyChallengeLeaderboardEntry
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
                
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < entry.stars ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(Theme.gold)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 2) {
                    Image(systemName: "creditcard.fill")
                        .font(.caption2)
                    Text("+\(entry.coinsReward)")
                        .font(.caption2)
                }
                .foregroundColor(Theme.gold)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DailyChallengePlayView: View {
    let challenge: DailyChallengeResponse
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var levelDefinition: LevelDefinition?
    @State private var scene: GameScene?
    @State private var isLoadingLevel = true
    @State private var loadError: String?
    @State private var levelStartTime: Date?
    
    @State private var completedStars: Int?
    @State private var completedStrokes: Int?
    @State private var attemptResult: DailyChallengeAttemptResponse?
    @State private var isSubmitting = false
    @State private var showMenuSheet = false
    @State private var currentStrokes: Int = 0
    
    var body: some View {
        Group {
            if isLoadingLevel {
                loadingView
            } else if let error = loadError {
                errorView(error)
            } else if let scene = scene {
                gameView(scene)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .task {
            await loadLevel()
        }
        .onAppear {
            AudioManager.shared.playMusic(.game)
        }
        .onDisappear {
            AudioManager.shared.playMusic(.menu)
        }
        .sheet(isPresented: $showMenuSheet) {
            DailyChallengeMenuSheet(
                onRetry: {
                    showMenuSheet = false
                    retryChallenge()
                },
                onExit: {
                    showMenuSheet = false
                    dismiss()
                }
            )
            .environmentObject(appState)
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            Text("Loading challenge...")
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text("Failed to load challenge")
                .font(.headline)
                .foregroundColor(.white)
            Text(error)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await loadLevel() }
            }
            .buttonStyle(FilledButtonStyle())
            .frame(width: 150)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }
    
    private func gameView(_ scene: GameScene) -> some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea(edges: .all)
            
            if completedStars == nil {
                VStack {
                    HStack(alignment: .center, spacing: 12) {
                        Button {
                            showMenuSheet = true
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                        
                        Text("Daily Challenge")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.5))
                            )
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "figure.golf")
                                .font(.system(size: 14, weight: .semibold))
                            Text("\(currentStrokes)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 54)
                    
                    Spacer()
                }
            }
            
            if let stars = completedStars {
                CompletionOverlay(
                    stars: stars,
                    strokes: completedStrokes ?? 0,
                    score: attemptResult?.score,
                    isSubmitting: isSubmitting,
                    onDismiss: { dismiss() }
                )
            }
        }
        .background(DisableSwipeBackGesture())
    }
    
    private func loadLevel() async {
        isLoadingLevel = true
        loadError = nil
        
        do {
            print("[DailyChallengePlay] Loading level from: '\(challenge.fileUrl)'")
            let definition = try await DailyChallengeService.shared.loadLevel(from: challenge.fileUrl)
            
            levelStartTime = Date()
            
            let gameScene = GameScene(
                level: definition,
                levelNumber: nil,
                skinImage: appState.equippedSkinImage
            )
            
            gameScene.onLevelComplete = { stars in
                Task { @MainActor in
                    await handleCompletion(stars: stars, strokes: gameScene.currentStrokes)
                }
            }
            gameScene.onStrokesChanged = { strokes in
                Task { @MainActor in
                    currentStrokes = strokes
                }
            }
            
            scene = gameScene
            levelDefinition = definition
        } catch {
            print("[DailyChallengePlay] Error loading level: \(error)")
            loadError = error.localizedDescription
        }
        
        isLoadingLevel = false
    }

    private func retryChallenge() {
        scene = nil
        currentStrokes = 0
        completedStars = nil
        completedStrokes = nil
        attemptResult = nil
        Task {
            await loadLevel()
        }
    }
    
    @MainActor
    private func handleCompletion(stars: Int, strokes: Int) async {
        let timeToPassMs: Int
        if let start = levelStartTime {
            timeToPassMs = Int(Date().timeIntervalSince(start) * 1000)
        } else {
            timeToPassMs = 60000
        }
        
        completedStars = stars
        completedStrokes = strokes
        isSubmitting = true
        
        do {
            attemptResult = try await DailyChallengeService.shared.submitAttempt(
                timeToPassMs: timeToPassMs,
                strokes: strokes,
                stars: stars
            )
            print("[DailyChallengePlay] Attempt submitted, score: \(attemptResult?.score ?? 0)")
        } catch {
            print("[DailyChallengePlay] Failed to submit attempt: \(error)")
        }
        
        isSubmitting = false
    }
}

private struct CompletionOverlay: View {
    let stars: Int
    let strokes: Int
    let score: Int?
    let isSubmitting: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Challenge Complete!")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { idx in
                        Image(systemName: idx < stars ? "star.fill" : "star")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.gold)
                            .scaleEffect(idx < stars ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6).delay(Double(idx) * 0.1), value: stars)
                    }
                }
                .padding(.vertical, 8)
                
                Text("\(strokes) strokes")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                if let score = score {
                    Text("Score: \(score)")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                } else if isSubmitting {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.white)
                        Text("Submitting...")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Button("Done") {
                    onDismiss()
                }
                .buttonStyle(FilledButtonStyle())
                .frame(width: 200)
                .disabled(isSubmitting)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: Theme.shadow, radius: 20, x: 0, y: 10)
            )
            .padding(40)
        }
    }
}

private struct DailyChallengeMenuSheet: View {
    @EnvironmentObject private var appState: AppState
    let onRetry: () -> Void
    let onExit: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Daily Challenge")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            Text("Paused")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                Button {
                    appState.musicEnabled.toggle()
                    AudioManager.shared.isMusicEnabled = appState.musicEnabled
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: appState.musicEnabled ? "music.note" : "music.note.slash")
                            .font(.title2)
                        Text("Music")
                            .font(.caption)
                    }
                    .foregroundColor(appState.musicEnabled ? Theme.accent : .gray)
                    .frame(width: 70, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Button {
                    appState.soundEffectsEnabled.toggle()
                    AudioManager.shared.isSoundEnabled = appState.soundEffectsEnabled
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: appState.soundEffectsEnabled ? "speaker.wave.2" : "speaker.slash")
                            .font(.title2)
                        Text("Sound")
                            .font(.caption)
                    }
                    .foregroundColor(appState.soundEffectsEnabled ? Theme.accent : .gray)
                    .frame(width: 70, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            .padding(.vertical, 4)
            
            Divider()
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                Button {
                    onRetry()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Retry")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.accent)
                    )
                }
                
                Button {
                    onExit()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Exit Challenge")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 2)
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .padding(.top, 16)
    }
}
