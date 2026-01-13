import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private let levelLibrary = LevelLibrary()

    @Published var currentUser: UserResponse? = nil

    @Published var coins: Int = 1500
    @Published var musicEnabled: Bool = true
    @Published var soundEffectsEnabled: Bool = true

    @Published var levels: [Level] = []
    @Published var shopItems: [ShopItem] = ShopItem.samples()
    @Published var leaderboard: [LeaderboardEntry] = LeaderboardEntry.samples()

    init() {
        reloadLevels()
    }

    func setCurrentUser(_ user: UserResponse) {
        currentUser = user
    }

    func logout() {
        Task {
            try? await AuthService.shared.signOut()
            currentUser = nil
        }
    }

    func loadExistingSession() async {
        do {
            let profile = try await AuthService.shared.fetchCurrentUser()
            currentUser = profile
        } catch {
            currentUser = nil
        }
    }

    func purchase(itemId: String) -> Bool {
        guard let index = shopItems.firstIndex(where: { $0.id == itemId }) else { return false }
        guard shopItems[index].owned == false else { return false }
        let price = shopItems[index].price
        guard coins >= price else { return false }
        coins -= price
        shopItems[index].owned = true
        return true
    }

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
}
