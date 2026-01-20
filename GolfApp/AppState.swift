import Combine
import Foundation
import SwiftUI
import UIKit
import FirebaseStorage

@MainActor
final class AppState: ObservableObject {
    private let levelLibrary = LevelLibrary()
    private let apiClient = APIClient.shared

    @Published var currentUser: UserResponse? = nil
    @Published var isLoadingUser: Bool = false
    
    var coins: Int {
        currentUser?.coins ?? 0
    }
    
    var equippedSkinId: String {
        currentUser?.equippedSkin ?? "default"
    }

    @Published var musicEnabled: Bool = true
    @Published var soundEffectsEnabled: Bool = true

    @Published var levels: [Level] = []
    @Published var shopItems: [ShopItem] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    
    @Published var equippedSkinImage: UIImage? = nil
    
    @Published var isLoadingShop: Bool = false
    @Published var isLoadingLeaderboard: Bool = false
    @Published var isLoadingLevels: Bool = false
    
    @Published var lastError: String? = nil

    init() {
        reloadLevels()
    }

    func setCurrentUser(_ user: UserResponse) {
        currentUser = user
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
    
    func refreshUser() async {
        do {
            let profile = try await AuthService.shared.fetchCurrentUser()
            currentUser = profile
        } catch {
            lastError = error.localizedDescription
        }
    }

    func reloadLevels() {
        let loadedLevels = levelLibrary.availableLevels()
        levels = loadedLevels.isEmpty ? Level.samples() : loadedLevels
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
        if stars > 0 {
            unlockNextLevel(after: levelID)
        }
    }
    
    private func unlockNextLevel(after levelID: Int) {
        let nextLevelID = levelID + 1
        if let nextIndex = levels.firstIndex(where: { $0.id == nextLevelID }) {
            levels[nextIndex].isLocked = false
        }
    }
    
    private func updateLevelLockStates() {
        let sortedLevels = levels.sorted { $0.id < $1.id }
        
        for (index, level) in sortedLevels.enumerated() {
            if level.id == 1 {
                if let idx = levels.firstIndex(where: { $0.id == level.id }) {
                    levels[idx].isLocked = false
                }
            } else {
                let previousLevelID = level.id - 1
                let previousLevelPassed = sortedLevels.first(where: { $0.id == previousLevelID })?.stars ?? 0 > 0
                
                if let idx = levels.firstIndex(where: { $0.id == level.id }) {
                    levels[idx].isLocked = !previousLevelPassed
                }
            }
        }
    }
    
    func loadLevelProgress() async {
        isLoadingLevels = true
        defer { isLoadingLevels = false }
        
        do {
            let progress = try await apiClient.getAllLevelProgress()
            
            for levelProgress in progress {
                if let index = levels.firstIndex(where: { $0.id == levelProgress.levelNumber }) {
                    levels[index].stars = levelProgress.stars
                    levels[index].bestTimeMs = levelProgress.timeToPassMs
                    levels[index].bestScore = levelProgress.score
                }
            }
            
            updateLevelLockStates()
        } catch {
            print("Failed to load level progress: \(error)")
            updateLevelLockStates()
        }
    }
    
    func completeLevel(levelNumber: Int, timeToPassMs: Int, stars: Int) async -> LevelProgressResponse? {
        do {
            let result = try await apiClient.completeLevel(
                levelNumber: levelNumber,
                timeToPassMs: timeToPassMs,
                stars: stars
            )
            
            updateStars(for: levelNumber, stars: result.stars)
            if let index = levels.firstIndex(where: { $0.id == levelNumber }) {
                levels[index].bestTimeMs = result.timeToPassMs
                levels[index].bestScore = result.score
            }
            
            await refreshUser()
            
            return result
        } catch {
            lastError = error.localizedDescription
            return nil
        }
    }

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
            if shopItems.isEmpty {
                print("🛍️ [AppState] Using sample shop items as fallback")
                shopItems = ShopItem.samples()
            }
        }
    }
    
    func purchase(itemId: String) async -> Bool {
        do {
            _ = try await apiClient.buySkin(skinId: itemId)
            
            if let index = shopItems.firstIndex(where: { $0.id == itemId }) {
                shopItems[index].owned = true
            }
            
            await refreshUser()
            
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
    
    func equipSkin(skinId: String) async -> Bool {
        do {
            _ = try await apiClient.equipSkin(skinId: skinId)
            
            for index in shopItems.indices {
                shopItems[index].equipped = (shopItems[index].id == skinId)
            }
            
            await refreshUser()
            
            await loadEquippedSkinImage()
            
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
    
    func loadEquippedSkinImage() async {
        print("🎨 [AppState] loadEquippedSkinImage() started")
        print("🎨 [AppState] equippedSkinId from user: '\(equippedSkinId)'")
        print("🎨 [AppState] shopItems count: \(shopItems.count)")
        
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
        
        if let cachedImage = await SkinImageCache.shared.getImage(for: item.imageUrl) {
            print("✅ [AppState] Got equipped skin image from cache")
            equippedSkinImage = cachedImage
        } else {
            print("❌ [AppState] Failed to get equipped skin image")
            equippedSkinImage = nil
        }
    }
    
    func preloadAllSkinImages() async {
        let paths = shopItems.compactMap { $0.imageUrl.isEmpty ? nil : $0.imageUrl }
        guard !paths.isEmpty else { return }
        
        print("📦 [AppState] Preloading \(paths.count) skin images...")
        await SkinImageCache.shared.preloadImages(for: paths)
    }
    
    func getSkinImageURL(for skinId: String) -> URL? {
        if let item = shopItems.first(where: { $0.id == skinId }) {
            return item.firebaseImageURL
        }
        return nil
    }

    func loadLeaderboard() async {
        isLoadingLeaderboard = true
        defer { isLoadingLeaderboard = false }
        
        do {
            let entries = try await apiClient.getGlobalLeaderboard()
            leaderboard = entries.map { LeaderboardEntry(from: $0) }
        } catch {
            lastError = error.localizedDescription
            if leaderboard.isEmpty {
                leaderboard = LeaderboardEntry.samples()
            }
        }
    }
    
    func getMyLeaderboardPosition() -> LeaderboardEntry? {
        guard let userId = currentUser?.id else { return nil }
        return leaderboard.first { $0.userId == userId }
    }

    func clearError() {
        lastError = nil
    }
}
