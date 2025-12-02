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


