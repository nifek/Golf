import Foundation
import FirebaseStorage

/// Service for loading daily challenge levels from Firebase Storage
actor DailyChallengeService {
    static let shared = DailyChallengeService()
    
    private let apiClient = APIClient.shared
    
    /// Cache for downloaded level definitions
    private var levelCache: [String: LevelDefinition] = [:]
    
    private init() {}
    
    // MARK: - Challenge API
    
    /// Get today's daily challenge info
    func getTodayChallenge() async throws -> DailyChallengeResponse {
        try await apiClient.getTodayChallenge()
    }
    
    /// Submit a daily challenge attempt
    func submitAttempt(timeToPassMs: Int, strokes: Int, stars: Int) async throws -> DailyChallengeAttemptResponse {
        try await apiClient.completeDailyChallenge(timeToPassMs: timeToPassMs, strokes: strokes, stars: stars)
    }
    
    /// Get today's leaderboard
    func getLeaderboard(limit: Int = 100) async throws -> [DailyChallengeLeaderboardEntry] {
        try await apiClient.getDailyChallengeLeaderboard(limit: limit)
    }
    
    // MARK: - Level Loading
    
    /// Load a level definition from Firebase Storage
    /// - Parameter storagePath: The path in Firebase Storage (e.g., "dailychallenge/level_2025_01_19.json")
    /// - Returns: The parsed LevelDefinition
    func loadLevel(from storagePath: String) async throws -> LevelDefinition {
        // Check cache first
        if let cached = levelCache[storagePath] {
            print("💾 [DailyChallengeService] Level cache HIT for '\(storagePath)'")
            return cached
        }
        
        print("📥 [DailyChallengeService] Loading level from Firebase Storage: '\(storagePath)'")
        
        // Get download URL from Firebase SDK
        let storage = Storage.storage()
        let reference = storage.reference(withPath: storagePath)
        
        let url: URL
        do {
            url = try await reference.downloadURL()
            print("✅ [DailyChallengeService] Got download URL: \(url.absoluteString)")
        } catch {
            print("❌ [DailyChallengeService] Failed to get download URL: \(error)")
            throw DailyChallengeError.levelNotFound
        }
        
        // Download the JSON data
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 [DailyChallengeService] HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw DailyChallengeError.downloadFailed
            }
        }
        
        print("📥 [DailyChallengeService] Downloaded \(data.count) bytes")
        
        // Parse the level definition
        do {
            let decoder = JSONDecoder()
            let level = try decoder.decode(LevelDefinition.self, from: data)
            print("✅ [DailyChallengeService] Parsed level successfully")
            
            // Cache it
            levelCache[storagePath] = level
            
            return level
        } catch {
            print("❌ [DailyChallengeService] Failed to parse level JSON: \(error)")
            throw DailyChallengeError.invalidLevelData
        }
    }
    
    /// Clear the level cache
    func clearCache() {
        levelCache.removeAll()
    }
}

// MARK: - Errors

enum DailyChallengeError: LocalizedError {
    case noChallengeToday
    case levelNotFound
    case downloadFailed
    case invalidLevelData
    
    var errorDescription: String? {
        switch self {
        case .noChallengeToday:
            return "No challenge available for today."
        case .levelNotFound:
            return "Challenge level not found."
        case .downloadFailed:
            return "Failed to download challenge level."
        case .invalidLevelData:
            return "Challenge level data is invalid."
        }
    }
}
