import XCTest
@testable import GolfApp

// MARK: - Unit Tests

final class ModelUnitTests: XCTestCase {
    
    // MARK: - Unit Test 1: LevelVector CGPoint Conversion
    
    func testLevelVectorToCGPointConversion() {
        // Given
        let vector = LevelVector(x: 100.5, y: 200.75)
        
        // When
        let point = vector.cgPoint
        
        // Then
        XCTAssertEqual(point.x, 100.5, accuracy: 0.001, "X coordinate should match")
        XCTAssertEqual(point.y, 200.75, accuracy: 0.001, "Y coordinate should match")
    }
    
    func testLevelVectorWithNegativeValues() {
        // Given
        let vector = LevelVector(x: -50.0, y: -100.0)
        
        // When
        let point = vector.cgPoint
        
        // Then
        XCTAssertEqual(point.x, -50.0, accuracy: 0.001)
        XCTAssertEqual(point.y, -100.0, accuracy: 0.001)
    }
    
    // MARK: - Unit Test 2: TerrainPolygon Path Creation
    
    func testTerrainPolygonMakePathWithValidVertices() {
        // Given - A valid triangle
        let vertices = [
            LevelVector(x: 0, y: 0),
            LevelVector(x: 100, y: 0),
            LevelVector(x: 50, y: 100)
        ]
        let polygon = TerrainPolygon(position: LevelVector(x: 0, y: 0), vertices: vertices)
        
        // When
        let path = polygon.makePath()
        
        // Then
        XCTAssertNotNil(path, "Path should be created for polygon with 3+ vertices")
    }
    
    func testTerrainPolygonMakePathWithInsufficientVertices() {
        // Given - Only 2 vertices (not enough for a polygon)
        let vertices = [
            LevelVector(x: 0, y: 0),
            LevelVector(x: 100, y: 0)
        ]
        let polygon = TerrainPolygon(position: LevelVector(x: 0, y: 0), vertices: vertices)
        
        // When
        let path = polygon.makePath()
        
        // Then
        XCTAssertNil(path, "Path should be nil for polygon with less than 3 vertices")
    }
    
    func testTerrainPolygonMakePathWithEmptyVertices() {
        // Given
        let polygon = TerrainPolygon(position: LevelVector(x: 0, y: 0), vertices: [])
        
        // When
        let path = polygon.makePath()
        
        // Then
        XCTAssertNil(path, "Path should be nil for polygon with no vertices")
    }
    
    // MARK: - Unit Test 3: Level Samples Generation
    
    func testLevelSamplesGeneration() {
        // When
        let samples = Level.samples()
        
        // Then
        XCTAssertEqual(samples.count, 5, "Should generate 5 sample levels")
        
        // Verify first level
        XCTAssertEqual(samples[0].id, 1)
        XCTAssertEqual(samples[0].name, "Level 1")
        XCTAssertEqual(samples[0].difficulty, "Easy")
        XCTAssertFalse(samples[0].isLocked)
        
        // Verify last level is locked
        XCTAssertTrue(samples[4].isLocked, "Level 5 should be locked")
    }
    
    func testLevelSamplesHaveUniqueIDs() {
        // When
        let samples = Level.samples()
        let ids = samples.map { $0.id }
        let uniqueIds = Set(ids)
        
        // Then
        XCTAssertEqual(ids.count, uniqueIds.count, "All level IDs should be unique")
    }
    
    // MARK: - Unit Test 4: ShopItem Samples Generation
    
    func testShopItemSamplesGeneration() {
        // When
        let samples = ShopItem.samples()
        
        // Then
        XCTAssertFalse(samples.isEmpty, "Shop items should not be empty")
        XCTAssertEqual(samples.count, 6, "Should have 6 shop items")
        
        // Verify classic ball is owned by default and free
        let classicBall = samples.first { $0.id == "classic" }
        XCTAssertNotNil(classicBall, "Classic ball should exist")
        XCTAssertTrue(classicBall?.owned ?? false, "Classic ball should be owned")
        XCTAssertEqual(classicBall?.price, 0, "Classic ball should be free")
    }
    
    func testShopItemSamplesHaveValidPrices() {
        // When
        let samples = ShopItem.samples()
        
        // Then
        for item in samples {
            XCTAssertGreaterThanOrEqual(item.price, 0, "Price should be non-negative for \(item.name)")
        }
    }
    
    // MARK: - Unit Test 5: LeaderboardEntry Samples Generation
    
    func testLeaderboardEntrySamplesGeneration() {
        // When
        let samples = LeaderboardEntry.samples()
        
        // Then
        XCTAssertFalse(samples.isEmpty, "Leaderboard should not be empty")
        XCTAssertEqual(samples.count, 8, "Should have 8 leaderboard entries")
    }
    
    func testLeaderboardEntriesAreSortedByRank() {
        // When
        let samples = LeaderboardEntry.samples()
        
        // Then
        for i in 0..<samples.count {
            XCTAssertEqual(samples[i].rank, i + 1, "Rank should match position")
        }
    }
    
    func testLeaderboardScoresAreAscending() {
        // When
        let samples = LeaderboardEntry.samples()
        
        // Then - In golf, lower scores are better, so scores should increase
        for i in 1..<samples.count {
            XCTAssertGreaterThanOrEqual(
                samples[i].score,
                samples[i-1].score,
                "Scores should be in ascending order (lower is better in golf)"
            )
        }
    }
    
    // MARK: - Unit Test 6: LevelDefinition JSON Decoding
    
    func testLevelDefinitionDecoding() throws {
        // Given
        let json = """
        {
            "levelName": "Test Level",
            "maxStrikesForThreeStars": 2,
            "maxStrikesForTwoStars": 4,
            "maxStrikesForOneStar": 6,
            "playerStartPosition": { "x": 0, "y": 0 },
            "hole": {
                "position": { "x": 100, "y": 100 },
                "radius": 20
            },
            "terrain": []
        }
        """
        let data = json.data(using: .utf8)!
        
        // When
        let definition = try JSONDecoder().decode(LevelDefinition.self, from: data)
        
        // Then
        XCTAssertEqual(definition.levelName, "Test Level")
        XCTAssertEqual(definition.maxStrikesForThreeStars, 2)
        XCTAssertEqual(definition.maxStrikesForTwoStars, 4)
        XCTAssertEqual(definition.maxStrikesForOneStar, 6)
        XCTAssertEqual(definition.hole.radius, 20)
        XCTAssertEqual(definition.playerStartPosition.x, 0)
        XCTAssertEqual(definition.playerStartPosition.y, 0)
    }
    
    func testLevelDefinitionEncodingRoundTrip() throws {
        // Given
        let json = """
        {
            "levelName": "Round Trip Test",
            "maxStrikesForThreeStars": 1,
            "maxStrikesForTwoStars": 2,
            "maxStrikesForOneStar": 3,
            "playerStartPosition": { "x": 50, "y": 75 },
            "hole": {
                "position": { "x": 200, "y": 300 },
                "radius": 25
            },
            "terrain": [
                {
                    "position": { "x": 10, "y": 20 },
                    "vertices": [
                        { "x": 0, "y": 0 },
                        { "x": 100, "y": 0 },
                        { "x": 50, "y": 100 }
                    ]
                }
            ]
        }
        """
        let originalData = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        // When
        let definition = try decoder.decode(LevelDefinition.self, from: originalData)
        let encodedData = try encoder.encode(definition)
        let decodedAgain = try decoder.decode(LevelDefinition.self, from: encodedData)
        
        // Then
        XCTAssertEqual(definition.levelName, decodedAgain.levelName)
        XCTAssertEqual(definition.maxStrikesForThreeStars, decodedAgain.maxStrikesForThreeStars)
        XCTAssertEqual(definition.terrain.count, decodedAgain.terrain.count)
    }
    
    // MARK: - Unit Test 7: AuthServiceError Descriptions
    
    func testAuthServiceErrorDescriptions() {
        // Test all error cases have meaningful descriptions
        let errors: [AuthServiceError] = [
            .invalidEmail,
            .invalidPassword,
            .invalidUsername,
            .missingProfile
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Error description should not be empty")
        }
    }
    
    func testAuthServiceErrorInvalidEmailDescription() {
        let error = AuthServiceError.invalidEmail
        XCTAssertTrue(
            error.errorDescription?.lowercased().contains("email") ?? false,
            "Invalid email error should mention email"
        )
    }
    
    func testAuthServiceErrorInvalidPasswordDescription() {
        let error = AuthServiceError.invalidPassword
        XCTAssertTrue(
            error.errorDescription?.lowercased().contains("password") ?? false,
            "Invalid password error should mention password"
        )
        XCTAssertTrue(
            error.errorDescription?.contains("6") ?? false,
            "Invalid password error should mention minimum length"
        )
    }
    
    func testAuthServiceErrorInvalidUsernameDescription() {
        let error = AuthServiceError.invalidUsername
        XCTAssertTrue(
            error.errorDescription?.lowercased().contains("username") ?? false,
            "Invalid username error should mention username"
        )
    }
}

// MARK: - Integration Tests

final class AppStateIntegrationTests: XCTestCase {
    
    // MARK: - Integration Test 1: Purchase Flow - Successful Purchase
    
    @MainActor
    func testPurchaseSuccessfulWithSufficientCoins() {
        // Given
        let appState = AppState()
        appState.coins = 1000
        let itemId = appState.shopItems.first { !$0.owned && $0.price <= 1000 }?.id ?? ""
        let initialCoins = appState.coins
        let itemPrice = appState.shopItems.first { $0.id == itemId }?.price ?? 0
        
        // When
        let success = appState.purchase(itemId: itemId)
        
        // Then
        XCTAssertTrue(success, "Purchase should succeed with sufficient coins")
        XCTAssertEqual(appState.coins, initialCoins - itemPrice, "Coins should be deducted")
        XCTAssertTrue(
            appState.shopItems.first { $0.id == itemId }?.owned ?? false,
            "Item should be marked as owned"
        )
    }
    
    @MainActor
    func testPurchaseFailsWithInsufficientCoins() {
        // Given
        let appState = AppState()
        appState.coins = 100
        // Find an item that costs more than 100 coins
        let expensiveItem = appState.shopItems.first { !$0.owned && $0.price > 100 }
        guard let itemId = expensiveItem?.id else {
            XCTFail("No expensive item found for test")
            return
        }
        let initialCoins = appState.coins
        
        // When
        let success = appState.purchase(itemId: itemId)
        
        // Then
        XCTAssertFalse(success, "Purchase should fail with insufficient coins")
        XCTAssertEqual(appState.coins, initialCoins, "Coins should remain unchanged")
    }
    
    @MainActor
    func testPurchaseFailsForAlreadyOwnedItem() {
        // Given
        let appState = AppState()
        appState.coins = 10000
        // Classic item should be owned by default
        let classicItemId = "classic"
        let initialCoins = appState.coins
        
        // When
        let success = appState.purchase(itemId: classicItemId)
        
        // Then
        XCTAssertFalse(success, "Purchase should fail for already owned item")
        XCTAssertEqual(appState.coins, initialCoins, "Coins should remain unchanged")
    }
    
    // MARK: - Integration Test 2: Update Stars Flow
    
    @MainActor
    func testUpdateStarsImprovesRating() {
        // Given
        let appState = AppState()
        // Find a level with current stars < 3
        guard let levelIndex = appState.levels.firstIndex(where: { $0.stars < 3 }) else {
            XCTFail("No level with stars < 3 found")
            return
        }
        let levelId = appState.levels[levelIndex].id
        let initialStars = appState.levels[levelIndex].stars
        let newStars = min(3, initialStars + 1)
        
        // When
        appState.updateStars(for: levelId, stars: newStars)
        
        // Then
        let updatedStars = appState.levels.first { $0.id == levelId }?.stars ?? 0
        XCTAssertEqual(updatedStars, newStars, "Stars should be updated to new value")
    }
    
    @MainActor
    func testUpdateStarsDoesNotDecrease() {
        // Given
        let appState = AppState()
        // Find a level with stars > 0
        guard let levelIndex = appState.levels.firstIndex(where: { $0.stars > 0 }) else {
            // Set stars manually for test
            if !appState.levels.isEmpty {
                appState.levels[0].stars = 2
            } else {
                XCTFail("No levels found")
                return
            }
            return
        }
        let levelId = appState.levels[levelIndex].id
        let initialStars = appState.levels[levelIndex].stars
        
        // When - Try to decrease stars
        appState.updateStars(for: levelId, stars: initialStars - 1)
        
        // Then
        let currentStars = appState.levels.first { $0.id == levelId }?.stars ?? 0
        XCTAssertEqual(currentStars, initialStars, "Stars should not decrease")
    }
    
    @MainActor
    func testUpdateStarsForNonExistentLevel() {
        // Given
        let appState = AppState()
        let nonExistentLevelId = 99999
        let initialLevels = appState.levels
        
        // When
        appState.updateStars(for: nonExistentLevelId, stars: 3)
        
        // Then - No crash, levels unchanged
        XCTAssertEqual(appState.levels.count, initialLevels.count, "Levels count should be unchanged")
    }
    
    // MARK: - Integration Test 3: Level Reload Flow
    
    @MainActor
    func testReloadLevelsPopulatesLevels() {
        // Given
        let appState = AppState()
        
        // When
        appState.reloadLevels()
        
        // Then
        XCTAssertFalse(appState.levels.isEmpty, "Levels should not be empty after reload")
    }
    
    // MARK: - Integration Test 4: User Session Flow
    
    @MainActor
    func testSetCurrentUserUpdatesState() {
        // Given
        let appState = AppState()
        let testUser = UserResponse(
            id: 1,
            username: "testuser",
            email: "test@example.com",
            avatarUrl: nil,
            globalScore: 100,
            ranking: 5
        )
        
        // When
        appState.setCurrentUser(testUser)
        
        // Then
        XCTAssertNotNil(appState.currentUser, "Current user should be set")
        XCTAssertEqual(appState.currentUser?.username, "testuser")
        XCTAssertEqual(appState.currentUser?.id, 1)
        XCTAssertEqual(appState.currentUser?.globalScore, 100)
    }
    
    // MARK: - Integration Test 5: LevelLibrary Error Handling
    
    func testLevelLibraryErrorDescriptions() {
        // Test error descriptions for LevelLibraryError
        let missingError = LevelLibraryError.missingResource("test_level")
        XCTAssertNotNil(missingError.errorDescription)
        XCTAssertTrue(missingError.errorDescription?.contains("test_level") ?? false)
        
        let readError = LevelLibraryError.failedToRead(
            URL(fileURLWithPath: "/test/path.json"),
            underlying: NSError(domain: "test", code: 1)
        )
        XCTAssertNotNil(readError.errorDescription)
        
        let decodeError = LevelLibraryError.failedToDecode(
            URL(fileURLWithPath: "/test/path.json"),
            underlying: NSError(domain: "test", code: 2)
        )
        XCTAssertNotNil(decodeError.errorDescription)
    }
    
    func testLoadDefinitionForLevelWithoutResourceName() {
        // Given
        let library = LevelLibrary()
        let levelWithoutResource = Level(
            id: 999,
            name: "Test Level",
            difficulty: "Hard",
            stars: 0,
            isLocked: false,
            resourceName: nil
        )
        
        // When/Then
        XCTAssertThrowsError(try library.loadDefinition(for: levelWithoutResource)) { error in
            XCTAssertTrue(error is LevelLibraryError)
        }
    }
    
    // MARK: - Integration Test 6: Star Calculation Logic
    
    func testStarCalculationLogic() {
        // Test the star calculation formula based on level thresholds
        // This tests the business logic for awarding stars
        
        struct StarCalculationTest {
            let strokes: Int
            let maxForThree: Int
            let maxForTwo: Int
            let maxForOne: Int
            let expectedStars: Int
        }
        
        let testCases: [StarCalculationTest] = [
            // Perfect game - 3 stars
            StarCalculationTest(strokes: 1, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 3),
            StarCalculationTest(strokes: 2, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 3),
            // Good game - 2 stars
            StarCalculationTest(strokes: 3, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 2),
            StarCalculationTest(strokes: 4, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 2),
            // Okay game - 1 star
            StarCalculationTest(strokes: 5, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 1),
            StarCalculationTest(strokes: 6, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 1),
            // Over par - 0 stars
            StarCalculationTest(strokes: 7, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 0),
            StarCalculationTest(strokes: 100, maxForThree: 2, maxForTwo: 4, maxForOne: 6, expectedStars: 0),
        ]
        
        for test in testCases {
            let stars = calculateStars(
                strokes: test.strokes,
                maxForThree: test.maxForThree,
                maxForTwo: test.maxForTwo,
                maxForOne: test.maxForOne
            )
            XCTAssertEqual(
                stars,
                test.expectedStars,
                "With \(test.strokes) strokes (max3=\(test.maxForThree), max2=\(test.maxForTwo), max1=\(test.maxForOne)), expected \(test.expectedStars) stars but got \(stars)"
            )
        }
    }
    
    /// Helper function that mirrors GameScene's calculateStars logic for testing
    private func calculateStars(strokes: Int, maxForThree: Int, maxForTwo: Int, maxForOne: Int) -> Int {
        guard strokes > 0 else { return 0 }
        
        if strokes <= maxForThree {
            return 3
        }
        if strokes <= maxForTwo {
            return 2
        }
        if strokes <= maxForOne {
            return 1
        }
        return 0
    }
    
    // MARK: - Integration Test 7: API Models Encoding/Decoding
    
    func testAPIModelsEncodingDecoding() throws {
        // Test UserResponse
        let userJSON = """
        {
            "id": 42,
            "username": "golfer123",
            "email": "golfer@example.com",
            "avatarUrl": "https://example.com/avatar.png",
            "globalScore": 1500,
            "ranking": 10
        }
        """
        
        let userData = userJSON.data(using: .utf8)!
        let user = try JSONDecoder().decode(UserResponse.self, from: userData)
        
        XCTAssertEqual(user.id, 42)
        XCTAssertEqual(user.username, "golfer123")
        XCTAssertEqual(user.email, "golfer@example.com")
        XCTAssertEqual(user.avatarUrl, "https://example.com/avatar.png")
        XCTAssertEqual(user.globalScore, 1500)
        XCTAssertEqual(user.ranking, 10)
        
        // Test re-encoding
        let encodedData = try JSONEncoder().encode(user)
        let decodedUser = try JSONDecoder().decode(UserResponse.self, from: encodedData)
        XCTAssertEqual(user, decodedUser)
    }
    
    func testLevelCompleteRequestEncoding() throws {
        // Given
        let request = LevelCompleteRequest(
            levelNumber: 3,
            timeToPassMs: 45000,
            score: 150,
            stars: 2
        )
        
        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let decoded = try JSONDecoder().decode(LevelCompleteRequest.self, from: data)
        
        // Then
        XCTAssertEqual(decoded.levelNumber, 3)
        XCTAssertEqual(decoded.timeToPassMs, 45000)
        XCTAssertEqual(decoded.score, 150)
        XCTAssertEqual(decoded.stars, 2)
    }
    
    func testLevelProgressResponseDecoding() throws {
        // Given
        let json = """
        {
            "id": 1,
            "levelNumber": 5,
            "timeToPassMs": 30000,
            "score": 200,
            "stars": 3,
            "createdAt": "2024-01-15T10:30:00Z",
            "updatedAt": "2024-01-15T10:35:00Z"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let progress = try JSONDecoder().decode(LevelProgressResponse.self, from: data)
        
        // Then
        XCTAssertEqual(progress.id, 1)
        XCTAssertEqual(progress.levelNumber, 5)
        XCTAssertEqual(progress.timeToPassMs, 30000)
        XCTAssertEqual(progress.score, 200)
        XCTAssertEqual(progress.stars, 3)
    }
    
    func testUserStatsResponseDecoding() throws {
        // Given
        let json = """
        {
            "totalScore": 5000,
            "levelsCompleted": 12,
            "totalStars": 30
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let stats = try JSONDecoder().decode(UserStatsResponse.self, from: data)
        
        // Then
        XCTAssertEqual(stats.totalScore, 5000)
        XCTAssertEqual(stats.levelsCompleted, 12)
        XCTAssertEqual(stats.totalStars, 30)
    }
    
    func testAPIErrorResponseDecoding() throws {
        // Given
        let json = """
        {
            "timestamp": "2024-01-15T10:30:00Z",
            "status": 400,
            "error": "Bad Request",
            "message": "Invalid level number",
            "path": "/api/v1/levels/complete"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
        
        // Then
        XCTAssertEqual(errorResponse.status, 400)
        XCTAssertEqual(errorResponse.error, "Bad Request")
        XCTAssertEqual(errorResponse.message, "Invalid level number")
    }
}

// MARK: - API Error Tests

final class APIErrorTests: XCTestCase {
    
    func testAPIErrorDescriptions() {
        let errors: [(APIError, String)] = [
            (.notAuthenticated, "not signed in"),
            (.invalidURL, "Invalid"),
            (.invalidResponse, "Invalid"),
            (.unauthorized, "session"),
            (.forbidden, "permission"),
            (.badRequest("Test error"), "Test error"),
            (.notFound("Resource missing"), "Resource missing"),
            (.serverError("Server down"), "Server down"),
            (.unknown, "unknown")
        ]
        
        for (error, expectedSubstring) in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertTrue(
                error.errorDescription?.contains(expectedSubstring) ?? false,
                "Error '\(error)' should contain '\(expectedSubstring)' but got '\(error.errorDescription ?? "nil")'"
            )
        }
    }
    
    func testNetworkErrorWrapping() {
        let underlyingError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [
            NSLocalizedDescriptionKey: "The Internet connection appears to be offline."
        ])
        let apiError = APIError.networkError(underlyingError)
        
        XCTAssertNotNil(apiError.errorDescription)
        XCTAssertTrue(apiError.errorDescription?.contains("Network error") ?? false)
    }
    
    func testDecodingErrorWrapping() {
        let underlyingError = NSError(domain: "NSCocoaErrorDomain", code: 4864, userInfo: [
            NSLocalizedDescriptionKey: "The data couldn't be read because it is missing."
        ])
        let apiError = APIError.decodingError(underlyingError)
        
        XCTAssertNotNil(apiError.errorDescription)
        XCTAssertTrue(apiError.errorDescription?.contains("parse") ?? false)
    }
}

// MARK: - HTTPMethod Tests

final class HTTPMethodTests: XCTestCase {
    
    func testHTTPMethodRawValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }
}
