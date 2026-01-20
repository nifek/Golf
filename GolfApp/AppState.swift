import Combine
import Foundation
import SwiftUI
import UIKit
import FirebaseStorage

@MainActor
final class AppState: ObservableObject {
    private let levelLibrary = LevelLibrary()
    private let apiClient = APIClient.shared

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
    
    // MARK: - Equipped Skin Image (cached for game use)
    @Published var equippedSkinImage: UIImage? = nil
    
    // MARK: - Loading States
    @Published var isLoadingShop: Bool = false
    @Published var isLoadingLeaderboard: Bool = false
    @Published var isLoadingLevels: Bool = false
    
    // MARK: - Error State
    @Published var lastError: String? = nil

    init() {
        reloadLevels()
    }

    // MARK: - User Management

    func setCurrentUser(_ user: UserResponse) {
        currentUser = user
        // Load equipped skin image when user is set
        Task {
            await loadEquippedSkinImage()
        }
    }

    func logout() {
        Task {
            try? await AuthService.shared.signOut()
            currentUser = nil
            shopItems = []
            leaderboard = []
            equippedSkinImage = nil
        }
    }

    func loadExistingSession() async {
        isLoadingUser = true
        defer { isLoadingUser = false }
        
        do {
            let profile = try await AuthService.shared.fetchCurrentUser()
            currentUser = profile
            await loadEquippedSkinImage()
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
        // Apply initial lock states (level 1 unlocked, rest locked until progress loaded)
        updateLevelLockStates()
    }

    func levelDefinition(for level: Level) throws -> LevelDefinition {
        try levelLibrary.loadDefinition(for: level)
    }
    
    func updateStars(for levelID: Int, stars: Int) {
        guard let index = levels.firstIndex(where: { $0.id == levelID }) else { return }
        if stars > levels[index].stars {
            levels[index].stars = stars
        }
        // Unlock the next level if this one was completed
        if stars > 0 {
            unlockNextLevel(after: levelID)
        }
    }
    
    /// Unlock the next level after completing a level
    private func unlockNextLevel(after levelID: Int) {
        let nextLevelID = levelID + 1
        if let nextIndex = levels.firstIndex(where: { $0.id == nextLevelID }) {
            levels[nextIndex].isLocked = false
        }
    }
    
    /// Update locked state for all levels based on progress
    private func updateLevelLockStates() {
        // Sort levels by ID to ensure proper order
        let sortedLevels = levels.sorted { $0.id < $1.id }
        
        for (index, level) in sortedLevels.enumerated() {
            if level.id == 1 {
                // Level 1 is always unlocked
                if let idx = levels.firstIndex(where: { $0.id == level.id }) {
                    levels[idx].isLocked = false
                }
            } else {
                // Level N is unlocked if level N-1 has stars > 0
                let previousLevelID = level.id - 1
                let previousLevelPassed = sortedLevels.first(where: { $0.id == previousLevelID })?.stars ?? 0 > 0
                
                if let idx = levels.firstIndex(where: { $0.id == level.id }) {
                    levels[idx].isLocked = !previousLevelPassed
                }
            }
        }
    }
    
    /// Load all level progress from API and update local levels
    func loadLevelProgress() async {
        isLoadingLevels = true
        defer { isLoadingLevels = false }
        
        do {
            let progress = try await apiClient.getAllLevelProgress()
            
            // Update local levels with progress data
            for levelProgress in progress {
                if let index = levels.firstIndex(where: { $0.id == levelProgress.levelNumber }) {
                    levels[index].stars = levelProgress.stars
                    levels[index].bestTimeMs = levelProgress.timeToPassMs
                    levels[index].bestScore = levelProgress.score
                }
            }
            
            // Update lock states based on progress
            updateLevelLockStates()
        } catch {
            // Silently fail - levels will show 0 stars
            print("Failed to load level progress: \(error)")
            // Still update lock states based on local data
            updateLevelLockStates()
        }
    }
    
    /// Submit level completion to backend
    func completeLevel(levelNumber: Int, timeToPassMs: Int, stars: Int) async -> LevelProgressResponse? {
        do {
            let result = try await apiClient.completeLevel(
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

    // MARK: - Shop / Skins Management

    /// Load all skins from API
    func loadShop() async {
        print("🛍️ [AppState] loadShop() started")
        isLoadingShop = true
        defer { isLoadingShop = false }
        
        do {
            print("🛍️ [AppState] Fetching skins from API...")
            let skins = try await apiClient.getAllSkins()
            print("🛍️ [AppState] Got \(skins.count) skins from API")
            
            for skin in skins {
                print("🛍️ [AppState] Skin: id='\(skin.id)', imageUrl='\(skin.imageUrl)', owned=\(skin.owned), equipped=\(skin.equipped)")
            }
            
            shopItems = skins.map { ShopItem(from: $0) }
            print("🛍️ [AppState] Mapped to \(shopItems.count) shop items")
        } catch {
            print("❌ [AppState] loadShop error: \(error)")
            lastError = error.localizedDescription
            // Fallback to samples if API fails
            if shopItems.isEmpty {
                print("🛍️ [AppState] Using sample shop items as fallback")
                shopItems = ShopItem.samples()
            }
        }
    }
    
    /// Purchase a skin
    func purchase(itemId: String) async -> Bool {
        do {
            _ = try await apiClient.buySkin(skinId: itemId)
            
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
            _ = try await apiClient.equipSkin(skinId: skinId)
            
            // Update local shop items
            for index in shopItems.indices {
                shopItems[index].equipped = (shopItems[index].id == skinId)
            }
            
            // Refresh user to get updated equippedSkin
            await refreshUser()
            
            // Load the new skin image for game use
            await loadEquippedSkinImage()
            
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
    
    /// Load the equipped skin image from cache (or Firebase Storage if not cached)
    func loadEquippedSkinImage() async {
        print("🎨 [AppState] loadEquippedSkinImage() started")
        print("🎨 [AppState] equippedSkinId from user: '\(equippedSkinId)'")
        print("🎨 [AppState] shopItems count: \(shopItems.count)")
        
        // Find equipped skin
        let equippedItem = shopItems.first { $0.equipped } ?? shopItems.first { $0.id == equippedSkinId }
        
        guard let item = equippedItem else {
            print("⚠️ [AppState] No equipped item found in shopItems!")
            equippedSkinImage = nil
            return
        }
        
        print("🎨 [AppState] Found equipped item: id='\(item.id)', imageUrl='\(item.imageUrl)'")
        
        guard !item.imageUrl.isEmpty else {
            print("⚠️ [AppState] imageUrl is empty for equipped item")
            equippedSkinImage = nil
            return
        }
        
        // Use cache to get the image
        if let cachedImage = await SkinImageCache.shared.getImage(for: item.imageUrl) {
            print("✅ [AppState] Got equipped skin image from cache")
            equippedSkinImage = cachedImage
        } else {
            print("❌ [AppState] Failed to get equipped skin image")
            equippedSkinImage = nil
        }
    }
    
    /// Preload all skin images into cache for faster display
    func preloadAllSkinImages() async {
        let paths = shopItems.compactMap { $0.imageUrl.isEmpty ? nil : $0.imageUrl }
        guard !paths.isEmpty else { return }
        
        print("📦 [AppState] Preloading \(paths.count) skin images...")
        await SkinImageCache.shared.preloadImages(for: paths)
    }
    
    /// Get skin image URL for a specific skin ID
    func getSkinImageURL(for skinId: String) -> URL? {
        if let item = shopItems.first(where: { $0.id == skinId }) {
            return item.firebaseImageURL
        }
        return nil
    }

    // MARK: - Leaderboard Management

    /// Load global leaderboard
    func loadLeaderboard() async {
        isLoadingLeaderboard = true
        defer { isLoadingLeaderboard = false }
        
        do {
            let entries = try await apiClient.getGlobalLeaderboard()
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
