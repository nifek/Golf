import SpriteKit

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private enum PhysicsCategory {
        static let player: UInt32 = 0x1 << 0
        static let hole: UInt32 = 0x1 << 1
        static let terrain: UInt32 = 0x1 << 2
    }

    private let level: LevelDefinition

    private let player = SKShapeNode(circleOfRadius: 16)
    private let hole = SKShapeNode(circleOfRadius: 20)
    private var terrainNodes: [SKShapeNode] = []

    private var swingCount = 0
    private let swingLabel = SKLabelNode(text: "Swings: 0")
    private let winLabel = SKLabelNode(text: "")

    private var startTouch = CGPoint.zero
    private var endTouch = CGPoint.zero

    private let minVelocity: CGFloat = 5
    private let maxImpulse: CGFloat = 120

    init(level: LevelDefinition, size: CGSize = CGSize(width: 414, height: 896)) {
        self.level = level
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .gray
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)

        setupCameraIfNeeded()
        setupPlayer()
        setupHole()
        setupTerrain()
        setupLabels()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        updateLabelPositions()
    }

    private func setupCameraIfNeeded() {
        if camera == nil {
            let cameraNode = SKCameraNode()
            cameraNode.setScale(1.4)
            addChild(cameraNode)
            camera = cameraNode
        }
        camera?.position = .zero
    }

    private func setupPlayer() {
        player.strokeColor = .black
        player.fillColor = .black
        player.position = level.playerStartPosition.cgPoint
        player.physicsBody = SKPhysicsBody(circleOfRadius: 16)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.isDynamic = true
        player.physicsBody?.friction = 1.0
        player.physicsBody?.linearDamping = 1.0
        player.physicsBody?.restitution = 0.3
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.hole
        player.physicsBody?.collisionBitMask = UInt32.max
        addChild(player)
    }

    private func setupHole() {
        let radius = CGFloat(level.hole.radius)
        hole.strokeColor = .green
        hole.fillColor = .green
        hole.position = level.hole.position.cgPoint
        hole.path = CGPath(
            ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
            transform: nil
        )
        hole.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        hole.physicsBody?.isDynamic = false
        hole.physicsBody?.categoryBitMask = PhysicsCategory.hole
        hole.physicsBody?.contactTestBitMask = PhysicsCategory.player
        addChild(hole)
    }

    private func setupTerrain() {
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

    private func setupLabels() {
        swingLabel.fontColor = .white
        swingLabel.fontSize = 48
        swingLabel.horizontalAlignmentMode = .center

        winLabel.fontColor = .yellow
        winLabel.fontSize = 56
        winLabel.isHidden = true
        winLabel.horizontalAlignmentMode = .center

        camera?.addChild(swingLabel)
        camera?.addChild(winLabel)
        updateLabelPositions()
    }

    private func updateLabelPositions() {
        swingLabel.position = CGPoint(x: 0, y: size.height / 2 - 100)
        winLabel.position = .zero
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        startTouch = touch.location(in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        endTouch = touch.location(in: self)

        guard let velocity = player.physicsBody?.velocity else { return }
        if abs(velocity.dx) < minVelocity && abs(velocity.dy) < minVelocity {
            let swipeVector = CGVector(dx: endTouch.x - startTouch.x, dy: endTouch.y - startTouch.y)
            let golfVector = CGVector(dx: -swipeVector.dx, dy: -swipeVector.dy)
            let strength = min(hypot(golfVector.dx, golfVector.dy), maxImpulse)
            guard strength > 0 else { return }
            let angle = atan2(golfVector.dy, golfVector.dx)
            let cappedImpulse = CGVector(dx: cos(angle) * strength, dy: sin(angle) * strength)
            player.physicsBody?.applyImpulse(cappedImpulse)

            swingCount += 1
            swingLabel.text = "Swings: \(swingCount)"
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let nodes = (contact.bodyA.node, contact.bodyB.node)
        guard nodes.0 == player && nodes.1 == hole || nodes.1 == player && nodes.0 == hole else {
            return
        }
        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = false
        winLabel.text = "You Win! Swings: \(swingCount)"
        winLabel.isHidden = false
    }
}


