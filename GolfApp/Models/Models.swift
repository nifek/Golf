import Foundation

// MARK: - Level Model

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

// MARK: - Shop Item (maps to SkinResponse from API)

struct ShopItem: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var price: Int
    var imageUrl: String  // Firebase Storage path, e.g., "skins/fire.png"
    var owned: Bool
    var equipped: Bool
    
    /// Create from API response
    init(from skin: SkinResponse) {
        self.id = skin.id
        self.name = skin.name
        self.description = skin.description
        self.price = skin.price
        self.imageUrl = skin.imageUrl
        self.owned = skin.owned
        self.equipped = skin.equipped
    }
    
    /// Create locally
    init(id: String, name: String, description: String = "", price: Int, imageUrl: String = "", owned: Bool, equipped: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.imageUrl = imageUrl
        self.owned = owned
        self.equipped = equipped
    }
    
    /// Get the full Firebase Storage download URL
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

// MARK: - Leaderboard Entry

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
    
    /// Create from Daily Challenge Leaderboard API response
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
    }
    
    /// Create locally (for samples)
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
    }
}

// MARK: - Sample Data

extension Level {
    /// Levels start with 0 stars and locked (except level 1) - progress is loaded from API
    /// This generates levels dynamically based on the count parameter
    static func samples(count: Int = 9) -> [Level] {
        (1...count).map { levelNumber in
            Level(
                id: levelNumber,
                name: "Level \(levelNumber)",
                difficulty: difficultyForLevel(levelNumber),
                stars: 0,
                isLocked: levelNumber > 1,
                resourceName: "level_\(levelNumber)"
            )
        }
    }
    
    private static func difficultyForLevel(_ level: Int) -> String {
        switch level {
        case 1...2: return "Easy"
        case 3...4: return "Medium"
        case 5...6: return "Hard"
        case 7...8: return "Expert"
        default: return "Master"
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
