import Foundation

/// Service for managing level progress and statistics
actor LevelService {
    static let shared = LevelService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - Level Completion
    
    /// Submit level completion. Score is calculated on the backend.
    /// - Parameters:
    ///   - levelNumber: The level number (1-based)
    ///   - timeToPassMs: Time taken to complete in milliseconds
    ///   - stars: Stars earned (1-3)
    /// - Returns: The level progress response with calculated score
    func completeLevel(levelNumber: Int, timeToPassMs: Int, stars: Int) async throws -> LevelProgressResponse {
        guard levelNumber >= 1 else {
            throw LevelServiceError.invalidLevelNumber
        }
        guard stars >= 1 && stars <= 3 else {
            throw LevelServiceError.invalidStars
        }
        guard timeToPassMs > 0 else {
            throw LevelServiceError.invalidTime
        }
        
        return try await apiClient.completeLevel(
            levelNumber: levelNumber,
            timeToPassMs: timeToPassMs,
            stars: stars
        )
    }
    
    // MARK: - Progress Retrieval
    
    /// Get all level progress for the current user
    /// - Returns: Array of level progress, ordered by level number
    func getAllProgress() async throws -> [LevelProgressResponse] {
        try await apiClient.getAllLevelProgress()
    }
    
    /// Get progress for a specific level
    /// - Parameter levelNumber: The level number to fetch
    /// - Returns: The level progress if exists
    func getProgress(levelNumber: Int) async throws -> LevelProgressResponse {
        guard levelNumber >= 1 else {
            throw LevelServiceError.invalidLevelNumber
        }
        return try await apiClient.getLevelProgress(levelNumber: levelNumber)
    }
    
    // MARK: - Statistics
    
    /// Get aggregated user statistics
    /// - Returns: Total score, levels completed, and total stars
    func getStats() async throws -> UserStatsResponse {
        try await apiClient.getUserStats()
    }
}

// MARK: - Level Service Errors

enum LevelServiceError: LocalizedError {
    case invalidLevelNumber
    case invalidStars
    case invalidTime
    
    var errorDescription: String? {
        switch self {
        case .invalidLevelNumber:
            return "Level number must be at least 1."
        case .invalidStars:
            return "Stars must be between 1 and 3."
        case .invalidTime:
            return "Time must be greater than 0."
        }
    }
}
