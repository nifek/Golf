import SpriteKit
import UIKit

private enum PhysicsCategory {
    static let ball: UInt32 = 1 << 0
    static let hole: UInt32 = 1 << 1
    static let terrain: UInt32 = 1 << 2
    static let bounds: UInt32 = 1 << 3
}

final class GameScene: SKScene, SKPhysicsContactDelegate {
    private let level: LevelDefinition
    private let levelNumberText: String?
    private let skinImage: UIImage?
    private let ballRadius: CGFloat = 12
    private let maxStrokeLength: CGFloat = 200
    private let strokePowerScale: CGFloat = 0.25
    private let readyVelocityThreshold: CGFloat = 5
    private let autoStopVelocityThreshold: CGFloat = 1.5

    private var ballNode: SKNode?
    private var holeNode: SKShapeNode?
    private var terrainNodes: [SKShapeNode] = []
    private var aimLine: SKShapeNode?
    private var dragStartPoint: CGPoint?
    private var sceneIsConfigured = false
    private var levelCompleted = false
    
    private var strokes = 0 {
        didSet {
            onStrokesChanged?(strokes)
        }
    }
    
    var currentStrokes: Int { strokes }
    private var levelLabel: SKLabelNode?
    
    var onLevelComplete: ((Int) -> Void)?
    var onStrokesChanged: ((Int) -> Void)?

    init(level: LevelDefinition, levelNumber: Int?, skinImage: UIImage? = nil) {
        self.level = level
        self.levelNumberText = levelNumber.map { "Level \($0)" }
        self.skinImage = skinImage
        let screenSize = UIScreen.main.bounds.size
        let fallbackSize = CGSize(width: 768, height: 1024)
        super.init(size: screenSize == .zero ? fallbackSize : screenSize)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        size = view.bounds.size
        configureSceneIfNeeded()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if sceneIsConfigured {
            updateBackgroundSize()
            updateWorldBoundsBody()
            updateHUDLayout()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        guard let body = ballNode?.physicsBody else { return }
        let speed = body.velocity.magnitude
        if speed <= autoStopVelocityThreshold {
            body.velocity = .zero
            body.angularVelocity = 0
        }
    }

    private func configureSceneIfNeeded() {
        guard !sceneIsConfigured else { return }
        removeAllChildren()
        terrainNodes.removeAll()
        strokes = 0
        levelCompleted = false
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        setupBackground()
        updateWorldBoundsBody()
        setupHole()
        setupTerrain()
        setupBall()
        setupHUD()
        sceneIsConfigured = true
    }

    private func setupHUD() {
        if let levelText = levelNumberText {
            let levelNode = SKLabelNode(fontNamed: "AvenirNext-Bold")
            levelNode.text = levelText
            levelNode.fontSize = 28
            levelNode.fontColor = .white
            levelNode.horizontalAlignmentMode = .left
            levelNode.verticalAlignmentMode = .top
            levelNode.zPosition = 100
            addChild(levelNode)
            levelLabel = levelNode
            updateHUDLayout()
        } else {
            levelLabel = nil
        }
        
        onStrokesChanged?(strokes)
    }

    private func updateHUDLayout() {
        let topPadding: CGFloat = 90
        let horizontalPadding: CGFloat = 24
        let topY = size.height / 2 - topPadding
        levelLabel?.position = CGPoint(
            x: -size.width / 2 + horizontalPadding,
            y: topY
        )
    }

    private func setupBackground() {
        let backgroundColorTop = UIColor(red: 19/255, green: 94/255, blue: 59/255, alpha: 1)
        let backgroundNode = SKSpriteNode(color: backgroundColorTop, size: size)
        backgroundNode.name = "course-background"
        backgroundNode.position = .zero
        backgroundNode.zPosition = -10
        addChild(backgroundNode)
    }

    private func updateBackgroundSize() {
        if let backgroundNode = childNode(withName: "course-background") as? SKSpriteNode {
            backgroundNode.size = size
        }
    }

    private func worldRect() -> CGRect {
        CGRect(
            origin: CGPoint(x: -size.width / 2, y: -size.height / 2),
            size: size
        )
    }

    private func updateWorldBoundsBody() {
        let rect = worldRect()
        physicsBody = SKPhysicsBody(edgeLoopFrom: rect)
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = PhysicsCategory.bounds
        physicsBody?.collisionBitMask = PhysicsCategory.ball
        physicsBody?.contactTestBitMask = PhysicsCategory.ball
    }

    private func setupHole() {
        let radius = CGFloat(level.hole.radius)
        let hole = SKShapeNode(circleOfRadius: radius)
        hole.position = level.hole.position.cgPoint
        hole.fillColor = .black
        hole.strokeColor = .white
        hole.lineWidth = 2
        hole.zPosition = 5
        let body = SKPhysicsBody(circleOfRadius: radius * 0.8)
        body.isDynamic = false
        body.categoryBitMask = PhysicsCategory.hole
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.ball
        hole.physicsBody = body
        addChild(hole)
        holeNode = hole
    }

    private func setupBall() {
        let ball: SKNode
        
        if let skinTexture = skinImage {
            print("⚽ [GameScene] Using custom skin texture: \(skinTexture.size)")
            let texture = SKTexture(image: skinTexture)
            let spriteNode = SKSpriteNode(texture: texture)
            spriteNode.size = CGSize(width: ballRadius * 2, height: ballRadius * 2)
            spriteNode.position = level.playerStartPosition.cgPoint
            spriteNode.zPosition = 10
            ball = spriteNode
        } else {
            print("⚽ [GameScene] Using default white ball (no skin image provided)")
            let shapeNode = SKShapeNode(circleOfRadius: ballRadius)
            shapeNode.position = level.playerStartPosition.cgPoint
            shapeNode.fillColor = .white
            shapeNode.strokeColor = UIColor(white: 0.2, alpha: 1)
            shapeNode.lineWidth = 3
            shapeNode.zPosition = 10
            ball = shapeNode
        }

        let body = SKPhysicsBody(circleOfRadius: ballRadius)
        body.mass = 0.045
        body.friction = 0.02
        body.linearDamping = 0.35
        body.angularDamping = 0.5
        body.restitution = 0.45
        body.usesPreciseCollisionDetection = true
        body.categoryBitMask = PhysicsCategory.ball
        body.collisionBitMask = PhysicsCategory.bounds | PhysicsCategory.terrain
        body.contactTestBitMask = PhysicsCategory.hole | PhysicsCategory.terrain

        ball.physicsBody = body
        ballNode = ball
        addChild(ball)
    }

    private func setupTerrain() {
        for polygon in level.terrain {
            guard let path = polygon.makePath() else { continue }
            let node = SKShapeNode(path: path)
            node.position = polygon.position.cgPoint
            node.strokeColor = UIColor(red: 129/255, green: 96/255, blue: 54/255, alpha: 1)
            node.fillColor = UIColor(red: 164/255, green: 124/255, blue: 72/255, alpha: 1)
            node.strokeColor = node.fillColor
            node.lineWidth = 0
            node.isAntialiased = false
            node.zPosition = 3

            let body = SKPhysicsBody(edgeLoopFrom: path)
            body.isDynamic = false
            body.friction = 0.8
            body.restitution = 0.3
            body.categoryBitMask = PhysicsCategory.terrain
            body.collisionBitMask = PhysicsCategory.ball
            body.contactTestBitMask = PhysicsCategory.ball
            node.physicsBody = body

            terrainNodes.append(node)
            addChild(node)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let touch = touches.first,
            let ball = ballNode,
            let body = ball.physicsBody,
            body.velocity.magnitude <= readyVelocityThreshold
        else { return }

        let location = touch.location(in: self)
        let distanceFromBall = hypot(location.x - ball.position.x, location.y - ball.position.y)
        guard distanceFromBall <= ballRadius * 2.5 else { return }

        dragStartPoint = location
        showAimLine(from: ball.position, to: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let ball = ballNode, dragStartPoint != nil else { return }
        let location = touch.location(in: self)
        showAimLine(from: ball.position, to: location)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard
            let touch = touches.first,
            let ball = ballNode,
            let body = ball.physicsBody,
            let startPoint = dragStartPoint
        else {
            clearAimLine()
            return
        }

        let endLocation = touch.location(in: self)
        let dragVector = CGVector(dx: startPoint.x - endLocation.x, dy: startPoint.y - endLocation.y)
        let clampedVector = dragVector.clamped(maxLength: maxStrokeLength)
        let impulse = CGVector(dx: clampedVector.dx * strokePowerScale, dy: clampedVector.dy * strokePowerScale)

        if impulse.magnitude > 1 {
            body.applyImpulse(impulse)
            strokes += 1
            AudioManager.shared.playSound(.ballStroke)
        }

        self.dragStartPoint = nil
        clearAimLine()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        dragStartPoint = nil
        clearAimLine()
    }

    private func showAimLine(from start: CGPoint, to end: CGPoint) {
        let dragVector = CGVector(dx: start.x - end.x, dy: start.y - end.y)
        let clampedVector = dragVector.clamped(maxLength: maxStrokeLength)
        let aimEnd = CGPoint(x: start.x + clampedVector.dx, y: start.y + clampedVector.dy)

        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: aimEnd)

        if aimLine == nil {
            let lineNode = SKShapeNode(path: path)
            lineNode.strokeColor = UIColor.white.withAlphaComponent(0.7)
            lineNode.lineWidth = 3
            lineNode.zPosition = 20
            lineNode.lineCap = .round
            aimLine = lineNode
            addChild(lineNode)
        } else {
            aimLine?.path = path
        }
    }

    private func clearAimLine() {
        aimLine?.removeFromParent()
        aimLine = nil
    }

    func didBegin(_ contact: SKPhysicsContact) {
        guard !levelCompleted else { return }
        let categories = [
            contact.bodyA.categoryBitMask,
            contact.bodyB.categoryBitMask
        ]
        
        if categories.contains(PhysicsCategory.ball) && categories.contains(PhysicsCategory.hole) {
            handleBallEnteredHole()
            return
        }
        
        if categories.contains(PhysicsCategory.ball) {
            if categories.contains(PhysicsCategory.terrain) || categories.contains(PhysicsCategory.bounds) {
                if let ballBody = ballNode?.physicsBody, ballBody.velocity.magnitude > 20 {
                    AudioManager.shared.playSound(.wallHit)
                }
            }
        }
    }

    private func handleBallEnteredHole() {
        guard !levelCompleted, let ball = ballNode else { return }
        levelCompleted = true
        
        AudioManager.shared.playSound(.levelComplete)
        
        ball.physicsBody?.velocity = .zero
        let shrink = SKAction.scale(to: 0.1, duration: 0.35)
        let fade = SKAction.fadeOut(withDuration: 0.35)
        let group = SKAction.group([shrink, fade])
        
        let stars = calculateStars()
        print("DEBUG: Level completed with \(strokes) strokes. Max for 3 stars: \(level.maxStrikesForThreeStars), Max for 2 stars: \(level.maxStrikesForTwoStars), Max for 1 star: \(level.maxStrikesForOneStar). Calculated stars: \(stars)")
        onLevelComplete?(stars)
        
        ball.run(group)
    }
    
    private func calculateStars() -> Int {
        guard strokes > 0 else {
            print("WARNING: Level completed with 0 strokes! This shouldn't happen.")
            return 0
        }
        
        if strokes <= level.maxStrikesForThreeStars {
            return 3
        }

        if strokes <= level.maxStrikesForTwoStars {
            return 2
        }
        
        if strokes <= level.maxStrikesForOneStar {
            return 1
        }
        
        return 0
    }
}

private extension CGVector {
    var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }

    func clamped(maxLength: CGFloat) -> CGVector {
        guard magnitude > 0 else { return .zero }
        let factor = min(1, maxLength / magnitude)
        return CGVector(dx: dx * factor, dy: dy * factor)
    }
}
