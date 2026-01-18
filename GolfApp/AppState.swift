import Combine
import Foundation
import SwiftUI
import UIKit

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
            let progress = try await apiClient.getAllLevelProgress()
            
            // Update local levels with progress data
            for levelProgress in progress {
                if let index = levels.firstIndex(where: { $0.id == levelProgress.levelNumber }) {
                    levels[index].stars = levelProgress.stars
                    levels[index].bestTimeMs = levelProgress.timeToPassMs
                    levels[index].bestScore = levelProgress.score
                }
            }
        } catch {
            // Silently fail - levels will show 0 stars
            print("Failed to load level progress: \(error)")
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
    
    /// Load the equipped skin image from Firebase Storage
    func loadEquippedSkinImage() async {
        print("🎨 [AppState] loadEquippedSkinImage() started")
        print("🎨 [AppState] equippedSkinId from user: '\(equippedSkinId)'")
        print("🎨 [AppState] shopItems count: \(shopItems.count)")
        
        // Find equipped skin
        let equippedItem = shopItems.first { $0.equipped } ?? shopItems.first { $0.id == equippedSkinId }
        
        if let item = equippedItem {
            print("🎨 [AppState] Found equipped item: id='\(item.id)', imageUrl='\(item.imageUrl)'")
        } else {
            print("⚠️ [AppState] No equipped item found in shopItems!")
            equippedSkinImage = nil
            return
        }
        
        guard let item = equippedItem, let url = item.firebaseImageURL else {
            print("⚠️ [AppState] No firebaseImageURL for equipped item")
            equippedSkinImage = nil
            return
        }
        
        print("🌐 [AppState] Loading equipped skin image from: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 [AppState] HTTP Response: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("❌ [AppState] Non-200 status code!")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📄 [AppState] Response body: \(responseString.prefix(500))")
                    }
                }
            }
            
            print("📥 [AppState] Received \(data.count) bytes")
            
            if let image = UIImage(data: data) {
                print("✅ [AppState] Successfully created UIImage, size: \(image.size)")
                equippedSkinImage = image
            } else {
                print("❌ [AppState] Failed to create UIImage from data")
                equippedSkinImage = nil
            }
        } catch {
            print("❌ [AppState] Failed to load skin image: \(error)")
            equippedSkinImage = nil
        }
    }
    
    /// Get skin image URL for a specific skin ID
    func getSkinImageURL(for skinId: String) -> URL? {
        if let item = shopItems.first(where: { $0.id == skinId }) {
            return item.firebaseImageURL
        }
        return nil
    }

    // MARK: - Leaderboard Management

    /// Load today's daily challenge leaderboard
    func loadLeaderboard() async {
        isLoadingLeaderboard = true
        defer { isLoadingLeaderboard = false }
        
        do {
            let entries = try await apiClient.getDailyChallengeLeaderboard()
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
