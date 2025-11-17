import Foundation
import SwiftUI

final class AppState: ObservableObject {
    private let levelLibrary = LevelLibrary()

    @Published var currentUser: User? = nil

    @Published var coins: Int = 1500
    @Published var musicEnabled: Bool = true
    @Published var soundEffectsEnabled: Bool = true

    @Published var levels: [Level] = []
    @Published var shopItems: [ShopItem] = ShopItem.samples()
    @Published var leaderboard: [LeaderboardEntry] = LeaderboardEntry.samples()

    init() {
        reloadLevels()
    }

    func setCurrentUser(_ user: User) {
        currentUser = user
    }

    func logout() {
        currentUser = nil
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
}


