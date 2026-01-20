import Foundation

enum LevelLibraryError: LocalizedError {
    case missingResource(String)
    case failedToRead(URL, underlying: Error)
    case failedToDecode(URL, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingResource(let message):
            return message
        case .failedToRead(let url, let underlying):
            return "Unable to read \(url.lastPathComponent): \(underlying.localizedDescription)"
        case .failedToDecode(let url, let underlying):
            return "Unable to decode \(url.lastPathComponent): \(underlying.localizedDescription)"
        }
    }
}

struct LevelLibrary {
    // Possible subdirectory paths where level JSONs might be located in the bundle
    private let possibleDirectories = ["Levels", "Views/Levels/Levels", nil]
    private let levelFileExtension = "json"
    private let decoder = JSONDecoder()

    func availableLevels() -> [Level] {
        // Try each possible directory to find level files
        var urls: [URL] = []
        
        for directory in possibleDirectories {
            if let foundUrls = Bundle.main.urls(
                forResourcesWithExtension: levelFileExtension,
                subdirectory: directory
            ) {
                // Filter only level_X.json files
                let levelUrls = foundUrls.filter { url in
                    let name = url.deletingPathExtension().lastPathComponent
                    return name.hasPrefix("level_")
                }
                if !levelUrls.isEmpty {
                    urls = levelUrls
                    print("📂 [LevelLibrary] Found \(levelUrls.count) level files in subdirectory: \(directory ?? "root")")
                    break
                }
            }
        }
        
        if urls.isEmpty {
            print("⚠️ [LevelLibrary] No level files found in bundle")
            return []
        }

        return urls
            .compactMap { url -> (Int, URL, LevelDefinition)? in
                // Extract level number from filename (e.g., "level_1.json" -> 1)
                let resourceName = url.deletingPathExtension().lastPathComponent
                guard let levelNumber = extractLevelNumber(from: resourceName) else {
                    print("⚠️ [LevelLibrary] Could not extract level number from: \(resourceName)")
                    return nil
                }
                guard let definition = try? decodeLevel(at: url) else {
                    print("⚠️ [LevelLibrary] Could not decode level: \(resourceName)")
                    return nil
                }
                return (levelNumber, url, definition)
            }
            .sorted { $0.0 < $1.0 } // Sort by level number
            .map { levelNumber, url, definition in
                let resourceName = url.deletingPathExtension().lastPathComponent
                return Level(
                    id: levelNumber,
                    name: definition.levelName,
                    difficulty: "Par \(definition.maxStrikesForThreeStars)",
                    stars: 0,
                    isLocked: levelNumber > 1, // Only level 1 is unlocked by default
                    resourceName: resourceName
                )
            }
    }
    
    /// Extract level number from filename (e.g., "level_1" -> 1, "level_123" -> 123)
    private func extractLevelNumber(from filename: String) -> Int? {
        // Match pattern "level_X" where X is a number
        let pattern = "level_(\\d+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: filename, options: [], range: NSRange(filename.startIndex..., in: filename)),
              let numberRange = Range(match.range(at: 1), in: filename) else {
            return nil
        }
        return Int(filename[numberRange])
    }

    func loadDefinition(for level: Level) throws -> LevelDefinition {
        guard let resourceName = level.resourceName else {
            throw LevelLibraryError.missingResource("Missing resource name for \(level.name).")
        }
        return try loadDefinition(named: resourceName)
    }

    func loadDefinition(named resourceName: String) throws -> LevelDefinition {
        // Try to find the file in possible directories
        for directory in possibleDirectories {
            if let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: levelFileExtension,
                subdirectory: directory
            ) {
                return try decodeLevel(at: url)
            }
        }
        
        // Also try without subdirectory
        if let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: levelFileExtension
        ) {
            return try decodeLevel(at: url)
        }
        
        throw LevelLibraryError.missingResource(
            "Could not locate \(resourceName).\(levelFileExtension) in bundle."
        )
    }
    
    /// Load a level definition from raw JSON data (used for daily challenges)
    func loadDefinition(from data: Data) throws -> LevelDefinition {
        do {
            return try decoder.decode(LevelDefinition.self, from: data)
        } catch let error as DecodingError {
            throw LevelLibraryError.failedToDecode(URL(string: "data://")!, underlying: error)
        } catch {
            throw LevelLibraryError.failedToRead(URL(string: "data://")!, underlying: error)
        }
    }

    private func decodeLevel(at url: URL) throws -> LevelDefinition {
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(LevelDefinition.self, from: data)
        } catch let error as DecodingError {
            throw LevelLibraryError.failedToDecode(url, underlying: error)
        } catch {
            throw LevelLibraryError.failedToRead(url, underlying: error)
        }
    }
}
