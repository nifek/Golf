import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private let levelLibrary = LevelLibrary()
    private let levelService = LevelService.shared
    private let skinService = SkinService.shared
    private let dailyChallengeService = DailyChallengeService.shared

    // MARK: - User State
    @Published var currentUser: UserResponse? = nil
    @Published var isLoadingUser: Bool = false
    
    // MARK: - Computed Properties from User
    var coins: Int {
        currentUser?.coins ?? 0
    }
    
    var equippedSkinId: String {
        currentUser?.equippedSkin ?? "default"
    }

    // MARK: - Settings
    @Published var musicEnabled: Bool = true
    @Published var soundEffectsEnabled: Bool = true

    // MARK: - Game Data
    @Published var levels: [Level] = []
    @Published var shopItems: [ShopItem] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var todayChallenge: DailyChallenge? = nil
    @Published var myAttempts: [DailyChallengeAttemptResponse] = []
    
    // MARK: - Loading States
    @Published var isLoadingShop: Bool = false
    @Published var isLoadingLeaderboard: Bool = false
    @Published var isLoadingChallenge: Bool = false
    @Published var isLoadingLevels: Bool = false
    
    // MARK: - Error State
    @Published var lastError: String? = nil

    init() {
        reloadLevels()
    }

    // MARK: - User Management

    func setCurrentUser(_ user: UserResponse) {
        currentUser = user
    }

    func logout() {
        Task {
            try? await AuthService.shared.signOut()
            currentUser = nil
            shopItems = []
            leaderboard = []
            todayChallenge = nil
            myAttempts = []
        }
    }

    func loadExistingSession() async {
        isLoadingUser = true
        defer { isLoadingUser = false }
        
        do {
            let profile = try await AuthService.shared.fetchCurrentUser()
            currentUser = profile
        } catch {
            currentUser = nil
        }
    }
    
    /// Refresh user profile from backend
    func refreshUser() async {
        do {
            let profile = try await AuthService.shared.fetchCurrentUser()
            currentUser = profile
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Level Management

    func reloadLevels() {
        let loadedLevels = levelLibrary.availableLevels()
        levels = loadedLevels.isEmpty ? Level.samples() : loadedLevels
    }

    func levelDefinition(for level: Level) throws -> LevelDefinition {
        try levelLibrary.loadDefinition(for: level)
    }
    
    func updateStars(for levelID: Int, stars: Int) {
        guard let index = levels.firstIndex(where: { $0.id == levelID }) else { return }
        if stars > levels[index].stars {
            levels[index].stars = stars
        }
    }
    
    /// Load all level progress from API and update local levels
    func loadLevelProgress() async {
        isLoadingLevels = true
        defer { isLoadingLevels = false }
        
        do {
            let progress = try await levelService.getAllProgress()
            
            // Update local levels with progress data
            for levelProgress in progress {
                if let index = levels.firstIndex(where: { $0.id == levelProgress.levelNumber }) {
                    levels[index].stars = levelProgress.stars
                    levels[index].bestTimeMs = levelProgress.timeToPassMs
                    levels[index].bestScore = levelProgress.score
                }
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Submit level completion to backend
    func completeLevel(levelNumber: Int, timeToPassMs: Int, stars: Int) async -> LevelProgressResponse? {
        do {
            let result = try await levelService.completeLevel(
                levelNumber: levelNumber,
                timeToPassMs: timeToPassMs,
                stars: stars
            )
            
            // Update local state
            updateStars(for: levelNumber, stars: result.stars)
            if let index = levels.firstIndex(where: { $0.id == levelNumber }) {
                levels[index].bestTimeMs = result.timeToPassMs
                levels[index].bestScore = result.score
            }
            
            // Refresh user to get updated globalScore
            await refreshUser()
            
            return result
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
    
    /// Get user statistics
    func getUserStats() async -> UserStatsResponse? {
        do {
            return try await levelService.getStats()
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Shop / Skins Management

    /// Load all skins from API
    func loadShop() async {
        isLoadingShop = true
        defer { isLoadingShop = false }
        
        do {
            let skins = try await skinService.getAllSkins()
            shopItems = skins.map { ShopItem(from: $0) }
        } catch {
            lastError = error.localizedDescription
            // Fallback to samples if API fails
            if shopItems.isEmpty {
                shopItems = ShopItem.samples()
            }
        }
    }
    
    /// Purchase a skin
    func purchase(itemId: String) async -> Bool {
        do {
            let result = try await skinService.buySkin(skinId: itemId)
            
            // Update local shop item
            if let index = shopItems.firstIndex(where: { $0.id == itemId }) {
                shopItems[index].owned = true
            }
            
            // Refresh user to get updated coin balance
            await refreshUser()
            
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
    
    /// Equip a skin
    func equipSkin(skinId: String) async -> Bool {
        do {
            _ = try await skinService.equipSkin(skinId: skinId)
            
            // Update local shop items
            for index in shopItems.indices {
                shopItems[index].equipped = (shopItems[index].id == skinId)
            }
            
            // Refresh user to get updated equippedSkin
            await refreshUser()
            
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Daily Challenge Management

    /// Load today's daily challenge
    func loadTodayChallenge() async {
        isLoadingChallenge = true
        defer { isLoadingChallenge = false }
        
        do {
            let response = try await dailyChallengeService.getTodayChallenge()
            todayChallenge = DailyChallenge(from: response)
        } catch {
            lastError = error.localizedDescription
            todayChallenge = nil
        }
    }
    
    /// Submit a daily challenge attempt
    func completeDailyChallenge(timeToPassMs: Int, strokes: Int, stars: Int) async -> DailyChallengeAttemptResponse? {
        do {
            let result = try await dailyChallengeService.completeChallenge(
                timeToPassMs: timeToPassMs,
                strokes: strokes,
                stars: stars
            )
            
            // Add to local attempts
            myAttempts.insert(result, at: 0)
            
            // Update today's challenge user stats
            if var challenge = todayChallenge {
                challenge.userAttempts += 1
                if let currentBest = challenge.userBestStars {
                    challenge.userBestStars = max(currentBest, stars)
                } else {
                    challenge.userBestStars = stars
                }
                todayChallenge = challenge
            }
            
            return result
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }
    
    /// Load my attempts for today
    func loadMyAttempts() async {
        do {
            myAttempts = try await dailyChallengeService.getMyAttempts()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Leaderboard Management

    /// Load today's daily challenge leaderboard
    func loadLeaderboard() async {
        isLoadingLeaderboard = true
        defer { isLoadingLeaderboard = false }
        
        do {
            let entries = try await dailyChallengeService.getLeaderboard()
            leaderboard = entries.map { LeaderboardEntry(from: $0) }
        } catch {
            lastError = error.localizedDescription
            // Fallback to samples if API fails
            if leaderboard.isEmpty {
                leaderboard = LeaderboardEntry.samples()
            }
        }
    }
    
    /// Find current user's position in leaderboard
    func getMyLeaderboardPosition() -> LeaderboardEntry? {
        guard let userId = currentUser?.id else { return nil }
        return leaderboard.first { $0.userId == userId }
    }

    // MARK: - Error Handling

    func clearError() {
        lastError = nil
    }
}
