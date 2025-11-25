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
    private let levelDirectory = "../Levels"
    private let levelFileExtension = "json"
    private let decoder = JSONDecoder()

    func availableLevels() -> [Level] {
        guard let urls = Bundle.main.urls(
            forResourcesWithExtension: levelFileExtension,
            subdirectory: levelDirectory
        ) else {
            return []
        }

        return urls
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .enumerated()
            .compactMap { idx, url in
                guard let definition = try? decodeLevel(at: url) else {
                    return nil
                }
                let resourceName = url
                    .deletingPathExtension()
                    .lastPathComponent
                return Level(
                    id: idx + 1,
                    name: definition.levelName,
                    difficulty: "Par —",
                    stars: 0,
                    isLocked: false,
                    resourceName: resourceName
                )
            }
    }

    func loadDefinition(for level: Level) throws -> LevelDefinition {
        guard let resourceName = level.resourceName else {
            throw LevelLibraryError.missingResource("Missing resource name for \(level.name).")
        }
        return try loadDefinition(named: resourceName)
    }

    func loadDefinition(named resourceName: String) throws -> LevelDefinition {
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: levelFileExtension
        ) else {
            throw LevelLibraryError.missingResource(
                "Could not locate \(resourceName).\(levelFileExtension) in \(levelDirectory)/."
            )
        }
        return try decodeLevel(at: url)
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
