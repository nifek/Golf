import Foundation

struct User: Identifiable, Equatable {
    let id: String
    var username: String
    var avatarSystemName: String = "person.crop.circle"
}

struct Level: Identifiable, Hashable {
    let id: Int
    var name: String
    var difficulty: String
    var stars: Int
    var isLocked: Bool
}

struct ShopItem: Identifiable, Hashable {
    let id: String
    var name: String
    var price: Int
    var owned: Bool
}

struct LeaderboardEntry: Identifiable, Hashable {
    let id = UUID()
    var rank: Int
    var username: String
    var score: Int
    var avatarSystemName: String = "person.crop.circle"
}

extension Level {
    static func samples() -> [Level] {
        [
            Level(id: 1, name: "Level 1", difficulty: "Easy", stars: 3, isLocked: false),
            Level(id: 2, name: "Level 2", difficulty: "Medium", stars: 2, isLocked: false),
            Level(id: 3, name: "Level 3", difficulty: "Hard", stars: 0, isLocked: true),
            Level(id: 4, name: "Level 4", difficulty: "?", stars: 0, isLocked: true),
            Level(id: 5, name: "Level 5", difficulty: "?", stars: 0, isLocked: true)
        ]
    }
}

extension ShopItem {
    static func samples() -> [ShopItem] {
        [
            ShopItem(id: "happy", name: "Happy Gilmore", price: 750, owned: false),
            ShopItem(id: "8ball", name: "8-Ball", price: 500, owned: false),
            ShopItem(id: "disco", name: "Disco Ball", price: 1000, owned: false),
            ShopItem(id: "fire", name: "Fireball", price: 500, owned: false),
            ShopItem(id: "globe", name: "Globe Ball", price: 1500, owned: false),
            ShopItem(id: "classic", name: "Classic", price: 0, owned: true)
        ]
    }
}

extension LeaderboardEntry {
    static func samples() -> [LeaderboardEntry] {
        [
            LeaderboardEntry(rank: 1, username: "furby73", score: 10),
            LeaderboardEntry(rank: 2, username: "nifeshe", score: 11),
            LeaderboardEntry(rank: 3, username: "lilchicha", score: 13),
            LeaderboardEntry(rank: 4, username: "three_crows", score: 23),
            LeaderboardEntry(rank: 5, username: "tourist", score: 33),
            LeaderboardEntry(rank: 6, username: "BenQ", score: 42),
            LeaderboardEntry(rank: 7, username: "gepardo", score: 58),
            LeaderboardEntry(rank: 8, username: "Dyilik", score: 91)
        ]
    }
}


