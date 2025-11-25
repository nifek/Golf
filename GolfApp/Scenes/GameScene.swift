private func setupTerrain() {
    // Each terrain node's path and physics body use the same local (relative) coordinates.
    // The node is positioned at its anchor; the path and body are untransformed.
    for polygon in level.terrain {
        guard let path = polygon.makePath() else { continue }
        let node = SKShapeNode(path: path)
        node.strokeColor = .brown
        node.fillColor = .brown
        node.lineWidth = 1.5
        node.position = polygon.position.cgPoint
        node.physicsBody = SKPhysicsBody(polygonFrom: path)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.terrain
        terrainNodes.append(node)
        addChild(node)
    }
}
