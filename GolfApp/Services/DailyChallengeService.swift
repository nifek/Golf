import Foundation

/// Service for managing daily challenge operations
actor DailyChallengeService {
    static let shared = DailyChallengeService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - Challenge Retrieval
    
    /// Get today's daily challenge with user participation stats
    /// - Returns: Today's challenge information
    func getTodayChallenge() async throws -> DailyChallengeResponse {
        try await apiClient.getTodayChallenge()
    }
    
    /// Get challenge for a specific date
    /// - Parameter date: Date in YYYY-MM-DD format
    /// - Returns: The challenge for that date
    func getChallenge(date: Date) async throws -> DailyChallengeResponse {
        let dateString = formatDate(date)
        return try await apiClient.getChallenge(date: dateString)
    }
    
    // MARK: - Challenge Completion
    
    /// Submit an attempt for today's challenge
    /// - Parameters:
    ///   - timeToPassMs: Time taken in milliseconds
    ///   - strokes: Number of strokes taken
    ///   - stars: Stars earned (1-3)
    /// - Returns: The attempt response with calculated score
    func completeChallenge(timeToPassMs: Int, strokes: Int, stars: Int) async throws -> DailyChallengeAttemptResponse {
        guard timeToPassMs > 0 else {
            throw DailyChallengeError.invalidTime
        }
        guard strokes >= 1 else {
            throw DailyChallengeError.invalidStrokes
        }
        guard stars >= 1 && stars <= 3 else {
            throw DailyChallengeError.invalidStars
        }
        
        return try await apiClient.completeDailyChallenge(
            timeToPassMs: timeToPassMs,
            strokes: strokes,
            stars: stars
        )
    }
    
    // MARK: - User Attempts
    
    /// Get all of the current user's attempts for today's challenge
    /// - Returns: Array of attempts, ordered by stars (desc) then time (asc)
    func getMyAttempts() async throws -> [DailyChallengeAttemptResponse] {
        try await apiClient.getMyAttempts()
    }
    
    /// Get user's attempts for a specific date's challenge
    /// - Parameter date: The date to fetch attempts for
    /// - Returns: Array of attempts for that date
    func getMyAttempts(date: Date) async throws -> [DailyChallengeAttemptResponse] {
        let dateString = formatDate(date)
        return try await apiClient.getMyAttempts(date: dateString)
    }
    
    // MARK: - Leaderboard
    
    /// Get today's leaderboard
    /// - Parameter limit: Maximum number of entries (default: 100)
    /// - Returns: Array of leaderboard entries with rankings
    func getLeaderboard(limit: Int = 100) async throws -> [DailyChallengeLeaderboardEntry] {
        try await apiClient.getDailyChallengeLeaderboard(limit: limit)
    }
    
    /// Get leaderboard for a specific date
    /// - Parameters:
    ///   - date: The date to fetch leaderboard for
    ///   - limit: Maximum number of entries (default: 100)
    /// - Returns: Array of leaderboard entries
    func getLeaderboard(date: Date, limit: Int = 100) async throws -> [DailyChallengeLeaderboardEntry] {
        let dateString = formatDate(date)
        return try await apiClient.getDailyChallengeLeaderboard(date: dateString, limit: limit)
    }
    
    /// Find the current user's position in the leaderboard
    /// - Parameter userId: The user ID to search for
    /// - Returns: The user's leaderboard entry if found
    func findMyPosition(userId: Int) async throws -> DailyChallengeLeaderboardEntry? {
        let leaderboard = try await getLeaderboard()
        return leaderboard.first { $0.userId == userId }
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}

// MARK: - Daily Challenge Errors

enum DailyChallengeError: LocalizedError {
    case invalidTime
    case invalidStrokes
    case invalidStars
    case noChallengeToday
    
    var errorDescription: String? {
        switch self {
        case .invalidTime:
            return "Time must be greater than 0."
        case .invalidStrokes:
            return "Strokes must be at least 1."
        case .invalidStars:
            return "Stars must be between 1 and 3."
        case .noChallengeToday:
            return "No challenge available for today."
        }
    }
}
