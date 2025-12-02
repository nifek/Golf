import CoreGraphics
import Foundation

struct LevelVector: Codable, Hashable {
    let x: Double
    let y: Double

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct TerrainPolygon: Codable, Hashable {
    let position: LevelVector
    let vertices: [LevelVector]
}

struct LevelDefinition: Codable, Hashable {
    struct Hole: Codable, Hashable {
        let position: LevelVector
        let radius: Double
    }

    let levelName: String
    let playerStartPosition: LevelVector
    let hole: Hole
    let terrain: [TerrainPolygon]
    let maxStrikesForOneStar: Int
    let maxStrikesForTwoStars: Int
    let maxStrikesForThreeStars: Int?
    
    enum CodingKeys: String, CodingKey {
        case levelName
        case playerStartPosition
        case hole
        case terrain
        case maxStrikesForOneStar
        case maxStrikesForTwoStars
        case maxStrikesForThreeStars
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        levelName = try container.decode(String.self, forKey: .levelName)
        playerStartPosition = try container.decode(LevelVector.self, forKey: .playerStartPosition)
        hole = try container.decode(Hole.self, forKey: .hole)
        terrain = try container.decode([TerrainPolygon].self, forKey: .terrain)
        maxStrikesForOneStar = try container.decode(Int.self, forKey: .maxStrikesForOneStar)
        maxStrikesForTwoStars = try container.decode(Int.self, forKey: .maxStrikesForTwoStars)
        maxStrikesForThreeStars = try container.decodeIfPresent(Int.self, forKey: .maxStrikesForThreeStars)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(levelName, forKey: .levelName)
        try container.encode(playerStartPosition, forKey: .playerStartPosition)
        try container.encode(hole, forKey: .hole)
        try container.encode(terrain, forKey: .terrain)
        try container.encode(maxStrikesForOneStar, forKey: .maxStrikesForOneStar)
        try container.encode(maxStrikesForTwoStars, forKey: .maxStrikesForTwoStars)
        try container.encodeIfPresent(maxStrikesForThreeStars, forKey: .maxStrikesForThreeStars)
    }
}

extension TerrainPolygon {
    func makePath() -> CGPath? {
        guard vertices.count >= 3 else { return nil }
        let path = CGMutablePath()
        path.move(to: vertices[0].cgPoint)
        for vertex in vertices.dropFirst() {
            path.addLine(to: vertex.cgPoint)
        }
        path.closeSubpath()
        return path.copy()
    }
}


