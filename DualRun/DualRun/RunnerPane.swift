import SpriteKit
import UIKit

final class RunnerPane: SKNode {
    enum Role {
        case top
        case bottom

        var runnerColor: UIColor {
            switch self {
            case .top: return UIColor(red: 0.24, green: 0.86, blue: 1.0, alpha: 1)
            case .bottom: return UIColor(red: 1.0, green: 0.31, blue: 0.78, alpha: 1)
            }
        }

        var skyColor: UIColor {
            switch self {
            case .top: return UIColor(red: 0.06, green: 0.09, blue: 0.18, alpha: 1)
            case .bottom: return UIColor(red: 0.10, green: 0.06, blue: 0.16, alpha: 1)
            }
        }
    }

    let role: Role

    private let sky = SKSpriteNode()
    private let parallax = SKNode()
    private let ground = SKSpriteNode()
    private let player = SKShapeNode()
    private let eye = SKShapeNode(circleOfRadius: 3)
    private var stars: [SKShapeNode] = []
    private var obstacles: [Obstacle] = []

    private var paneSize = CGSize.zero
    private var feetY: CGFloat = RunTuning.groundY
    private var velocityY: CGFloat = 0
    private var slideRemaining: TimeInterval = 0
    private var crashed = false
    private var bottomInset: CGFloat = 0

    init(role: Role) {
        self.role = role
        super.init()
        sky.anchorPoint = .zero
        sky.color = role.skyColor
        addChild(sky)
        addChild(parallax)
        ground.anchorPoint = .zero
        ground.color = UIColor(white: 1, alpha: 0.14)
        addChild(ground)
        player.fillColor = role.runnerColor
        player.strokeColor = .clear
        player.lineWidth = 0
        eye.fillColor = UIColor(white: 0.08, alpha: 1)
        eye.strokeColor = .clear
        player.addChild(eye)
        addChild(player)
        for _ in 0..<14 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...1.8))
            star.fillColor = UIColor(white: 1, alpha: CGFloat.random(in: 0.25...0.7))
            star.strokeColor = .clear
            parallax.addChild(star)
            stars.append(star)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    func resize(to size: CGSize, bottomInset: CGFloat) {
        let sizeChanged = size != paneSize || bottomInset != self.bottomInset
        let previousGround = groundLine
        paneSize = size
        self.bottomInset = bottomInset
        sky.size = size
        ground.position = CGPoint(x: 0, y: bottomInset)
        ground.size = CGSize(width: size.width, height: RunTuning.groundY)
        if sizeChanged, size.height > bottomInset + 90 {
            let lower = bottomInset + RunTuning.groundY + 48
            let upper = max(lower + 1, size.height - 8)
            for star in stars {
                star.position = CGPoint(
                    x: CGFloat.random(in: 0...max(size.width, 1)),
                    y: CGFloat.random(in: lower...upper)
                )
            }
        }
        for obstacle in obstacles {
            obstacle.groundOrigin = groundLine
            obstacle.ceiling = paneSize.height
            layout(obstacle)
        }
        if velocityY == 0, abs(feetY - previousGround) < 1 {
            feetY = groundLine
        }
        placePlayer()
    }

    func reset() {
        crashed = false
        feetY = groundLine
        velocityY = 0
        slideRemaining = 0
        obstacles.forEach { $0.node.removeFromParent() }
        obstacles.removeAll()
        player.fillColor = role.runnerColor
        player.alpha = 1
        placePlayer()
    }

    func apply(_ action: ControlAction) {
        guard !crashed else { return }
        switch action {
        case .jump:
            guard isGrounded, slideRemaining <= 0 else { return }
            velocityY = RunTuning.jumpVelocity
        case .slide:
            guard isGrounded else { return }
            slideRemaining = RunTuning.slideDuration
            velocityY = 0
            feetY = groundLine
        }
        placePlayer()
    }

    func spawn(_ kind: ObstacleKind) {
        guard paneSize.width > 0 else { return }
        let obstacle = Obstacle(kind: kind, x: paneSize.width + 48, groundOrigin: groundLine, ceiling: paneSize.height)
        addChild(obstacle.node)
        obstacles.append(obstacle)
        layout(obstacle)
    }

    func update(dt: TimeInterval, scroll: CGFloat) -> Bool {
        guard !crashed, paneSize.width > 0 else { return false }
        let step = CGFloat(dt) * scroll
        for star in stars {
            star.position.x -= step * 0.35
            if star.position.x < -4 {
                star.position.x = paneSize.width + 4
                let lower = bottomInset + RunTuning.groundY + 48
                let upper = max(lower + 1, paneSize.height - 8)
                star.position.y = CGFloat.random(in: lower...upper)
            }
        }

        if slideRemaining > 0 {
            slideRemaining = max(0, slideRemaining - dt)
            feetY = groundLine
            velocityY = 0
        } else {
            velocityY -= RunTuning.gravity * CGFloat(dt)
            feetY += velocityY * CGFloat(dt)
            if feetY <= groundLine {
                feetY = groundLine
                velocityY = 0
            }
        }
        placePlayer()

        let playerBox = currentPlayerBox()
        var hit = false
        obstacles.removeAll { obstacle in
            obstacle.x -= step
            layout(obstacle)
            if !hit, playerBox.intersects(obstacle.hitBox, inset: RunTuning.hitInset) {
                hit = true
            }
            if obstacle.x < -80 {
                obstacle.node.removeFromParent()
                return true
            }
            return false
        }

        if hit {
            crashed = true
            player.fillColor = UIColor(red: 1, green: 0.28, blue: 0.32, alpha: 1)
            return true
        }
        return false
    }

    private var groundLine: CGFloat { bottomInset + RunTuning.groundY }

    private var isGrounded: Bool { feetY <= groundLine + 0.5 }

    private func currentPlayerBox() -> HitBox {
        let height = slideRemaining > 0 ? RunTuning.slideHeight : RunTuning.standHeight
        return HitBox(
            x: RunTuning.playerX - RunTuning.playerWidth / 2,
            y: feetY,
            width: RunTuning.playerWidth,
            height: height
        )
    }

    private func placePlayer() {
        let height = slideRemaining > 0 ? RunTuning.slideHeight : RunTuning.standHeight
        let width = RunTuning.playerWidth
        let rect = CGRect(x: -width / 2, y: 0, width: width, height: height)
        player.path = CGPath(roundedRect: rect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        player.position = CGPoint(x: RunTuning.playerX, y: feetY)
        eye.position = CGPoint(x: width * 0.18, y: height * 0.72)
        eye.isHidden = slideRemaining > 0
    }

    private func layout(_ obstacle: Obstacle) {
        let box = obstacle.hitBox
        obstacle.node.path = CGPath(
            roundedRect: CGRect(x: 0, y: 0, width: box.width, height: box.height),
            cornerWidth: 4,
            cornerHeight: 4,
            transform: nil
        )
        obstacle.node.position = CGPoint(x: box.x, y: box.y)
    }
}

private final class Obstacle {
    let kind: ObstacleKind
    var x: CGFloat
    var groundOrigin: CGFloat
    var ceiling: CGFloat
    let node = SKShapeNode()

    init(kind: ObstacleKind, x: CGFloat, groundOrigin: CGFloat, ceiling: CGFloat) {
        self.kind = kind
        self.x = x
        self.groundOrigin = groundOrigin
        self.ceiling = ceiling
        node.strokeColor = .clear
        node.lineWidth = 0
        switch kind {
        case .low:
            node.fillColor = UIColor(red: 1.0, green: 0.72, blue: 0.28, alpha: 1)
        case .high:
            node.fillColor = UIColor(red: 0.78, green: 0.86, blue: 1.0, alpha: 1)
        }
    }

    var hitBox: HitBox {
        switch kind {
        case .low:
            return HitBox(x: x, y: groundOrigin, width: RunTuning.obstacleWidth, height: RunTuning.lowHeight)
        case .high:
            let y = groundOrigin + RunTuning.highClearance
            return HitBox(
                x: x,
                y: y,
                width: RunTuning.obstacleWidth,
                height: max(24, ceiling - y)
            )
        }
    }
}

enum RunTuning {
    static let groundY: CGFloat = 22
    static let playerX: CGFloat = 86
    static let playerWidth: CGFloat = 28
    static let standHeight: CGFloat = 62
    static let slideHeight: CGFloat = 28
    static let lowHeight: CGFloat = 36
    static let highClearance: CGFloat = 42
    static let obstacleWidth: CGFloat = 34
    static let gravity: CGFloat = 1700
    static let jumpVelocity: CGFloat = 700
    static let slideDuration: TimeInterval = 0.62
    static let hitInset: CGFloat = 4
    static let baseSpeed: CGFloat = 250
    static let maxSpeed: CGFloat = 430
}
