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

struct LevelCompleteRequest: Codable {
    let levelNumber: Int
    let timeToPassMs: Int
    let score: Int
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

// MARK: - API Error

struct APIErrorResponse: Codable {
    let timestamp: String
    let status: Int
    let error: String
    let message: String
    let path: String
}

