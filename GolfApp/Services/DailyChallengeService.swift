import Foundation
import FirebaseStorage
actor DailyChallengeService {
    static let shared = DailyChallengeService()
    
    private let apiClient = APIClient.shared
    
    private var levelCache: [String: LevelDefinition] = [:]
    
    private init() {}
    
    func getTodayChallenge() async throws -> DailyChallengeResponse {
        try await apiClient.getTodayChallenge()
    }
    
    func submitAttempt(timeToPassMs: Int, strokes: Int, stars: Int) async throws -> DailyChallengeAttemptResponse {
        try await apiClient.completeDailyChallenge(timeToPassMs: timeToPassMs, strokes: strokes, stars: stars)
    }
    
    func getLeaderboard(limit: Int = 100) async throws -> [DailyChallengeLeaderboardEntry] {
        try await apiClient.getDailyChallengeLeaderboard(limit: limit)
    }
    
    func loadLevel(from storagePath: String) async throws -> LevelDefinition {
        if let cached = levelCache[storagePath] {
            print("💾 [DailyChallengeService] Level cache HIT for '\(storagePath)'")
            return cached
        }
        
        print("📥 [DailyChallengeService] Loading level from Firebase Storage: '\(storagePath)'")
        
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
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 [DailyChallengeService] HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                throw DailyChallengeError.downloadFailed
            }
        }
        
        print("📥 [DailyChallengeService] Downloaded \(data.count) bytes")
        
        do {
            let decoder = JSONDecoder()
            let level = try decoder.decode(LevelDefinition.self, from: data)
            print("✅ [DailyChallengeService] Parsed level successfully")
            
            levelCache[storagePath] = level
            
            return level
        } catch {
            print("❌ [DailyChallengeService] Failed to parse level JSON: \(error)")
            throw DailyChallengeError.invalidLevelData
        }
    }
    
    func clearCache() {
        levelCache.removeAll()
    }
}

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
