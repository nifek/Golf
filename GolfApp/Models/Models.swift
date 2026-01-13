import Foundation

// MARK: - Level Model (for local UI)

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

// MARK: - Shop Item (for local UI, maps to SkinResponse)

struct ShopItem: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var price: Int
    var imageUrl: String
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
    
    /// Create locally (for samples)
    init(id: String, name: String, description: String = "", price: Int, imageUrl: String = "", owned: Bool, equipped: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.imageUrl = imageUrl
        self.owned = owned
        self.equipped = equipped
    }
}

// MARK: - Leaderboard Entry (for local UI)

struct LeaderboardEntry: Identifiable, Hashable {
    let id: Int
    var rank: Int
    var userId: Int
    var username: String
    var avatarUrl: String?
    var score: Int
    var stars: Int?
    var bestTimeMs: Int?
    var strokes: Int?
    var coinsReward: Int?
    var avatarSystemName: String = "person.crop.circle"
    
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
        self.strokes = entry.strokes
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
        self.strokes = nil
        self.coinsReward = nil
    }
}

// MARK: - Daily Challenge (for local UI)

struct DailyChallenge: Identifiable, Hashable {
    let id: Int
    var challengeDate: String
    var fileUrl: String
    var title: String?
    var description: String?
    var totalParticipants: Int
    var userAttempts: Int
    var userBestStars: Int?
    
    /// Create from API response
    init(from response: DailyChallengeResponse) {
        self.id = response.id
        self.challengeDate = response.challengeDate
        self.fileUrl = response.fileUrl
        self.title = response.title
        self.description = response.description
        self.totalParticipants = response.totalParticipants
        self.userAttempts = response.userAttempts
        self.userBestStars = response.userBestStars
    }
}

// MARK: - Sample Data

extension Level {
    static func samples() -> [Level] {
        [
            Level(id: 1, name: "Level 1", difficulty: "Easy", stars: 3, isLocked: false, resourceName: "level_1"),
            Level(id: 2, name: "Level 2", difficulty: "Medium", stars: 2, isLocked: false, resourceName: "level_2"),
            Level(id: 3, name: "Level 3", difficulty: "Hard", stars: 0, isLocked: false, resourceName: "level_3"),
            Level(id: 4, name: "Level 4", difficulty: "Expert", stars: 0, isLocked: false, resourceName: "level_4"),
            Level(id: 5, name: "Level 5", difficulty: "?", stars: 0, isLocked: true, resourceName: "level_5")
        ]
    }
}

extension ShopItem {
    static func samples() -> [ShopItem] {
        [
            ShopItem(id: "default", name: "Default Ball", description: "The classic white golf ball", price: 0, owned: true, equipped: true),
            ShopItem(id: "golden", name: "Golden Ball", description: "A shiny golden golf ball", price: 500, owned: false),
            ShopItem(id: "fire", name: "Fire Ball", description: "A flaming hot golf ball", price: 1000, owned: false),
            ShopItem(id: "ice", name: "Ice Ball", description: "A freezing cold golf ball", price: 1000, owned: false),
            ShopItem(id: "rainbow", name: "Rainbow Ball", description: "A colorful rainbow golf ball", price: 2000, owned: false),
            ShopItem(id: "diamond", name: "Diamond Ball", description: "A sparkling diamond golf ball", price: 5000, owned: false)
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
