import Foundation
import FirebaseAuth

// MARK: - API Configuration

enum APIConfig {
    static let baseURL = "http://localhost:8089"
    static let apiVersion = "/api/v1"
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case badRequest(String)
    case notFound(String)
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You are not signed in."
        case .invalidURL:
            return "Invalid request URL."
        case .invalidResponse:
            return "Invalid server response."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to access this resource."
        case .badRequest(let message):
            return message
        case .notFound(let message):
            return message
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Client

actor APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    // MARK: - Token Retrieval
    
    private func getFirebaseToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw APIError.notAuthenticated
        }
        
        do {
            return try await user.getIDToken()
        } catch {
            throw APIError.notAuthenticated
        }
    }
    
    // MARK: - Generic Request
    
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let urlString = APIConfig.baseURL + APIConfig.apiVersion + endpoint
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if requiresAuth {
            let token = try await getFirebaseToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 400:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse?.message ?? "Bad request")
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.notFound(errorResponse?.message ?? "Not found")
        default:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.message ?? "Server error")
        }
    }
    
    // MARK: - Multipart Upload
    
    func uploadFile(
        endpoint: String,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fieldName: String = "file"
    ) async throws -> AvatarUploadResponse {
        let urlString = APIConfig.baseURL + APIConfig.apiVersion + endpoint
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let token = try await getFirebaseToken()
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(AvatarUploadResponse.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 400:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.badRequest(errorResponse?.message ?? "Bad request")
        case 401:
            throw APIError.unauthorized
        default:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(errorResponse?.message ?? "Server error")
        }
    }
    
    // MARK: - Skins Endpoints
    
    /// Get all available skins with ownership status
    func getAllSkins() async throws -> [SkinResponse] {
        try await request(endpoint: "/skins")
    }
    
    /// Get owned skins only
    func getOwnedSkins() async throws -> [SkinResponse] {
        try await request(endpoint: "/skins/owned")
    }
    
    /// Get currently equipped skin
    func getEquippedSkin() async throws -> SkinResponse {
        try await request(endpoint: "/skins/equipped")
    }
    
    /// Purchase a skin with coins
    func buySkin(skinId: String) async throws -> BuySkinResponse {
        let body = BuySkinRequest(skinId: skinId)
        return try await request(endpoint: "/skins/buy", method: .post, body: body)
    }
    
    /// Equip an owned skin
    func equipSkin(skinId: String) async throws -> SkinResponse {
        let body = EquipSkinRequest(skinId: skinId)
        return try await request(endpoint: "/skins/equip", method: .post, body: body)
    }
    
    // MARK: - Level Progress Endpoints
    
    /// Submit level completion (score calculated on backend)
    func completeLevel(levelNumber: Int, timeToPassMs: Int, stars: Int) async throws -> LevelProgressResponse {
        let body = LevelCompleteRequest(levelNumber: levelNumber, timeToPassMs: timeToPassMs, stars: stars)
        return try await request(endpoint: "/levels/complete", method: .post, body: body)
    }
    
    /// Get all level progress for current user
    func getAllLevelProgress() async throws -> [LevelProgressResponse] {
        try await request(endpoint: "/levels")
    }
    
    /// Get specific level progress
    func getLevelProgress(levelNumber: Int) async throws -> LevelProgressResponse {
        try await request(endpoint: "/levels/\(levelNumber)")
    }
    
    /// Get user stats
    func getUserStats() async throws -> UserStatsResponse {
        try await request(endpoint: "/levels/stats")
    }
    
    // MARK: - Daily Challenge Endpoints
    
    /// Get today's daily challenge
    func getTodayChallenge() async throws -> DailyChallengeResponse {
        try await request(endpoint: "/daily-challenge")
    }
    
    /// Submit daily challenge attempt
    func completeDailyChallenge(timeToPassMs: Int, strokes: Int, stars: Int) async throws -> DailyChallengeAttemptResponse {
        let body = DailyChallengeCompleteRequest(timeToPassMs: timeToPassMs, strokes: strokes, stars: stars)
        return try await request(endpoint: "/daily-challenge/complete", method: .post, body: body)
    }
    
    /// Get today's leaderboard
    func getDailyChallengeLeaderboard(limit: Int = 100) async throws -> [DailyChallengeLeaderboardEntry] {
        try await request(endpoint: "/daily-challenge/leaderboard?limit=\(limit)")
    }

    /// Get global leaderboard
    func getGlobalLeaderboard(limit: Int = 100) async throws -> [GlobalLeaderboardEntryResponse] {
        try await request(endpoint: "/users/leaderboard?limit=\(limit)")
    }
}
