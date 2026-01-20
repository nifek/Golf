import Foundation

struct Level: Identifiable, Hashable {
    let id: Int
    var name: String
    var difficulty: String
    var stars: Int
    var isLocked: Bool
    var resourceName: String?
    var bestTimeMs: Int?
    var bestScore: Int?
}

struct ShopItem: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var price: Int
    var imageUrl: String
    var owned: Bool
    var equipped: Bool
    
    init(from skin: SkinResponse) {
        self.id = skin.id
        self.name = skin.name
        self.description = skin.description
        self.price = skin.price
        self.imageUrl = skin.imageUrl
        self.owned = skin.owned
        self.equipped = skin.equipped
    }
    
    init(id: String, name: String, description: String = "", price: Int, imageUrl: String = "", owned: Bool, equipped: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.imageUrl = imageUrl
        self.owned = owned
        self.equipped = equipped
    }
    
    var firebaseImageURL: URL? {
        guard !imageUrl.isEmpty else {
            print("⚠️ [ShopItem '\(id)'] imageUrl is empty")
            return nil
        }
        print("🖼️ [ShopItem '\(id)'] Building URL for imageUrl: '\(imageUrl)'")
        let url = FirebaseStorageHelper.downloadURL(for: imageUrl)
        print("🖼️ [ShopItem '\(id)'] Result URL: \(url?.absoluteString ?? "nil")")
        return url
    }
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id: Int
    var rank: Int
    var userId: Int
    var username: String
    var avatarUrl: String?
    var score: Int
    var stars: Int?
    var bestTimeMs: Int?
    var coinsReward: Int?
    var coins: Int?
    
    init(from entry: DailyChallengeLeaderboardEntry) {
        self.id = entry.rank
        self.rank = entry.rank
        self.userId = entry.userId
        self.username = entry.username
        self.avatarUrl = entry.avatarUrl
        self.score = entry.score
        self.stars = entry.stars
        self.bestTimeMs = entry.bestTimeMs
        self.coinsReward = entry.coinsReward
        self.coins = nil
    }

    init(from entry: GlobalLeaderboardEntryResponse) {
        self.id = entry.rank
        self.rank = entry.rank
        self.userId = entry.userId
        self.username = entry.username
        self.avatarUrl = entry.avatarUrl
        self.score = entry.globalScore
        self.stars = nil
        self.bestTimeMs = nil
        self.coinsReward = nil
        self.coins = entry.coins
    }
    
    init(rank: Int, username: String, score: Int) {
        self.id = rank
        self.rank = rank
        self.userId = rank
        self.username = username
        self.avatarUrl = nil
        self.score = score
        self.stars = nil
        self.bestTimeMs = nil
        self.coinsReward = nil
        self.coins = nil
    }
}

extension Level {
    static func samples(count: Int = 9) -> [Level] {
        (1...count).map { levelNumber in
            Level(
                id: levelNumber,
                name: "Level \(levelNumber)",
                difficulty: "Par \(parForLevel(levelNumber))",
                stars: 0,
                isLocked: levelNumber > 1,
                resourceName: "level_\(levelNumber)"
            )
        }
    }
    
    private static func parForLevel(_ level: Int) -> Int {
        switch level {
        case 1: return 2
        case 2: return 2
        case 3: return 3
        case 4: return 3
        case 5: return 4
        case 6: return 4
        case 7: return 5
        case 8: return 5
        default: return 6
        }
    }
}

extension ShopItem {
    static func samples() -> [ShopItem] {
        [
            ShopItem(id: "default", name: "Default Ball", description: "The classic white golf ball", price: 0, imageUrl: "skins/default.png", owned: true, equipped: true),
            ShopItem(id: "golden", name: "Golden Ball", description: "A shiny golden golf ball", price: 500, imageUrl: "skins/golden.png", owned: false),
            ShopItem(id: "fire", name: "Fire Ball", description: "A flaming hot golf ball", price: 1000, imageUrl: "skins/fire.png", owned: false),
            ShopItem(id: "ice", name: "Ice Ball", description: "A freezing cold golf ball", price: 1000, imageUrl: "skins/ice.png", owned: false),
            ShopItem(id: "rainbow", name: "Rainbow Ball", description: "A colorful rainbow golf ball", price: 2000, imageUrl: "skins/rainbow.png", owned: false),
            ShopItem(id: "diamond", name: "Diamond Ball", description: "A sparkling diamond golf ball", price: 5000, imageUrl: "skins/diamond.png", owned: false)
        ]
    } 
}

extension LeaderboardEntry {
    static func samples() -> [LeaderboardEntry] {
        [
            LeaderboardEntry(rank: 1, username: "furby73", score: 3150),
            LeaderboardEntry(rank: 2, username: "nifeshe", score: 3100),
            LeaderboardEntry(rank: 3, username: "lilchicha", score: 3050),
            LeaderboardEntry(rank: 4, username: "three_crows", score: 3000),
            LeaderboardEntry(rank: 5, username: "tourist", score: 2950),
            LeaderboardEntry(rank: 6, username: "BenQ", score: 2900),
            LeaderboardEntry(rank: 7, username: "gepardo", score: 2850),
            LeaderboardEntry(rank: 8, username: "Dyilik", score: 2800)
        ]
    }
}
