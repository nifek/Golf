import Foundation

/// Service for managing skin purchases and equipment
actor SkinService {
    static let shared = SkinService()
    private let apiClient = APIClient.shared
    
    private init() {}
    
    // MARK: - Skin Retrieval
    
    /// Get all available skins with ownership and equipped status
    /// - Returns: Array of all skins with user-specific status
    func getAllSkins() async throws -> [SkinResponse] {
        try await apiClient.getAllSkins()
    }
    
    /// Get only the skins owned by the current user
    /// - Returns: Array of owned skins
    func getOwnedSkins() async throws -> [SkinResponse] {
        try await apiClient.getOwnedSkins()
    }
    
    /// Get the currently equipped skin
    /// - Returns: The equipped skin details
    func getEquippedSkin() async throws -> SkinResponse {
        try await apiClient.getEquippedSkin()
    }
    
    // MARK: - Purchases
    
    /// Purchase a skin using coins
    /// - Parameter skinId: The ID of the skin to purchase
    /// - Returns: Purchase result with remaining coins
    /// - Throws: `SkinServiceError` if purchase fails
    func buySkin(skinId: String) async throws -> BuySkinResponse {
        guard !skinId.isEmpty else {
            throw SkinServiceError.invalidSkinId
        }
        
        do {
            return try await apiClient.buySkin(skinId: skinId)
        } catch let error as APIError {
            switch error {
            case .badRequest(let message) where message.contains("already own"):
                throw SkinServiceError.alreadyOwned
            case .badRequest(let message) where message.contains("Not enough coins"):
                throw SkinServiceError.insufficientCoins
            case .notFound:
                throw SkinServiceError.skinNotFound
            default:
                throw error
            }
        }
    }
    
    // MARK: - Equipment
    
    /// Equip an owned skin
    /// - Parameter skinId: The ID of the skin to equip
    /// - Returns: The equipped skin details
    /// - Throws: `SkinServiceError` if equip fails
    func equipSkin(skinId: String) async throws -> SkinResponse {
        guard !skinId.isEmpty else {
            throw SkinServiceError.invalidSkinId
        }
        
        do {
            return try await apiClient.equipSkin(skinId: skinId)
        } catch let error as APIError {
            switch error {
            case .badRequest(let message) where message.contains("don't own"):
                throw SkinServiceError.notOwned
            case .notFound:
                throw SkinServiceError.skinNotFound
            default:
                throw error
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Check if user can afford a skin
    /// - Parameters:
    ///   - skinId: The skin ID to check
    ///   - userCoins: The user's current coin balance
    /// - Returns: True if user has enough coins
    func canAfford(skinId: String, userCoins: Int) async throws -> Bool {
        let skins = try await getAllSkins()
        guard let skin = skins.first(where: { $0.id == skinId }) else {
            throw SkinServiceError.skinNotFound
        }
        return userCoins >= skin.price
    }
    
    /// Get skins the user can afford but doesn't own
    /// - Parameter userCoins: The user's current coin balance
    /// - Returns: Array of affordable, unowned skins
    func getAffordableSkins(userCoins: Int) async throws -> [SkinResponse] {
        let skins = try await getAllSkins()
        return skins.filter { !$0.owned && $0.price <= userCoins }
    }
}

// MARK: - Skin Service Errors

enum SkinServiceError: LocalizedError {
    case invalidSkinId
    case skinNotFound
    case alreadyOwned
    case notOwned
    case insufficientCoins
    
    var errorDescription: String? {
        switch self {
        case .invalidSkinId:
            return "Invalid skin ID."
        case .skinNotFound:
            return "Skin not found."
        case .alreadyOwned:
            return "You already own this skin."
        case .notOwned:
            return "You don't own this skin."
        case .insufficientCoins:
            return "Not enough coins to purchase this skin."
        }
    }
}
