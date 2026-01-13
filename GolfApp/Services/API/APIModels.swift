import Foundation

// MARK: - Auth Responses

struct CheckUserResponse: Codable {
    let exists: Bool
    let firebaseUid: String
}

struct SyncUserRequest: Codable {
    let username: String
}

// MARK: - User

struct UserResponse: Codable, Equatable {
    let id: Int
    let username: String
    let email: String?
    let avatarUrl: String?
    let globalScore: Int
    let ranking: Int?
    let coins: Int
    let equippedSkin: String
}

struct UpdateProfileRequest: Codable {
    let username: String?
    let avatarUrl: String?
    
    init(username: String? = nil, avatarUrl: String? = nil) {
        self.username = username
        self.avatarUrl = avatarUrl
    }
}

struct AvatarUploadResponse: Codable {
    let avatarUrl: String
    let message: String
}

// MARK: - Level Progress

/// Request to complete a level. Score is calculated on the backend.
struct LevelCompleteRequest: Codable {
    let levelNumber: Int
    let timeToPassMs: Int
    let stars: Int
}

struct LevelProgressResponse: Codable, Equatable {
    let id: Int
    let levelNumber: Int
    let timeToPassMs: Int
    let score: Int
    let stars: Int
    let createdAt: String
    let updatedAt: String
}

struct UserStatsResponse: Codable, Equatable {
    let totalScore: Int
    let levelsCompleted: Int
    let totalStars: Int
}

// MARK: - Daily Challenge

struct DailyChallengeResponse: Codable, Equatable {
    let id: Int
    let challengeDate: String
    let fileUrl: String
    let title: String?
    let description: String?
    let createdAt: String
    let totalParticipants: Int
    let userAttempts: Int
    let userBestStars: Int?
}

struct DailyChallengeCompleteRequest: Codable {
    let timeToPassMs: Int
    let strokes: Int
    let stars: Int
}

struct DailyChallengeAttemptResponse: Codable, Equatable, Identifiable {
    let id: Int
    let score: Int
    let timeToPassMs: Int
    let strokes: Int
    let stars: Int
    let completedAt: String
    let userId: Int
    let username: String
    let avatarUrl: String?
}

struct DailyChallengeLeaderboardEntry: Codable, Equatable, Identifiable {
    let rank: Int
    let userId: Int
    let username: String
    let avatarUrl: String?
    let stars: Int
    let bestTimeMs: Int
    let strokes: Int
    let score: Int
    let achievedAt: String
    let coinsReward: Int
    
    var id: Int { rank }
}

// MARK: - Skins

struct SkinResponse: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let imageUrl: String
    let owned: Bool
    let equipped: Bool
}

struct BuySkinRequest: Codable {
    let skinId: String
}

struct BuySkinResponse: Codable {
    let skinId: String
    let skinName: String
    let pricePaid: Int
    let remainingCoins: Int
    let message: String
}

struct EquipSkinRequest: Codable {
    let skinId: String
}

// MARK: - Admin (Daily Challenge)

struct CreateDailyChallengeRequest: Codable {
    let challengeDate: String
    let fileUrl: String
    let title: String?
    let description: String?
    
    init(challengeDate: String, fileUrl: String, title: String? = nil, description: String? = nil) {
        self.challengeDate = challengeDate
        self.fileUrl = fileUrl
        self.title = title
        self.description = description
    }
}

struct RewardDistributionResult: Codable {
    let date: String
    let usersRewarded: Int
    let totalCoinsDistributed: Int
}

// MARK: - API Error

struct APIErrorResponse: Codable {
    let timestamp: String
    let status: Int
    let error: String
    let message: String
    let path: String
}
