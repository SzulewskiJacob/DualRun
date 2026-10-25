import SpriteKit
import UIKit

final class GameScene: SKScene {
    var safeInsets = UIEdgeInsets.zero {
        didSet {
            guard oldValue != safeInsets else { return }
            layoutWorld()
        }
    }

    private let topPane = RunnerPane(role: .top)
    private let bottomPane = RunnerPane(role: .bottom)
    private let centerBar = SKNode()
    private let barBackground = SKSpriteNode(color: UIColor(white: 0.05, alpha: 0.94), size: .zero)
    private let phaseLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let phaseDetail = SKLabelNode(fontNamed: "AvenirNext-Medium")
    private let countdownLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let jumpButton = ControlButton(name: "jump", title: "JUMP", color: UIColor(red: 0.24, green: 0.86, blue: 1, alpha: 1))
    private let slideButton = ControlButton(name: "slide", title: "SLIDE", color: UIColor(red: 1, green: 0.31, blue: 0.78, alpha: 1))
    private let overlay = SKNode()
    private let overlayTitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let overlayBody = SKLabelNode(fontNamed: "AvenirNext-Medium")

    private var phase: ControlPhase = .sync
    private var phaseRemaining: TimeInterval = 16
    private var spawnRemaining: TimeInterval = 1.3
    private var scriptedSpawns = 0
    private var distance: CGFloat = 0
    private var state: RunState = .ready
    private var lastUpdate: TimeInterval?

    private enum RunState {
        case ready
        case playing
        case dead
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.09, alpha: 1)
        anchorPoint = .zero
        addChild(bottomPane)
        addChild(topPane)
        addChild(centerBar)
        addChild(scoreLabel)
        addChild(overlay)
        buildChrome()
        layoutWorld()
        showReady()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutWorld()
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if let lastUpdate {
            dt = min(1.0 / 20.0, max(0, currentTime - lastUpdate))
        } else {
            dt = 1.0 / 60.0
        }
        lastUpdate = currentTime
        guard state == .playing else { return }

        let speed = min(RunTuning.maxSpeed, RunTuning.baseSpeed + distance * 0.012)
        distance += speed * CGFloat(dt)
        scoreLabel.text = "\(Int(distance / 14)) m"

        phaseRemaining -= dt
        countdownLabel.text = "\(max(0, Int(ceil(phaseRemaining))))s"
        if phaseRemaining <= 0 {
            phase = phase.opposite
            phaseRemaining = 16
            refreshPhaseLabel(announce: true)
        }

        spawnRemaining -= dt
        if spawnRemaining <= 0 {
            spawnPair()
            let gap = max(300, 180 + speed * 0.62)
            spawnRemaining = TimeInterval(gap / speed)
        }

        let topHit = topPane.update(dt: dt, scroll: speed)
        let bottomHit = bottomPane.update(dt: dt, scroll: speed)
        if topHit || bottomHit {
            finishRun(topHit: topHit, bottomHit: bottomHit)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch state {
        case .ready:
            startRun()
        case .dead:
            showReady()
            startRun()
        case .playing:
            for touch in touches {
                guard let name = controlName(at: touch.location(in: self)) else { continue }
                let action: ControlAction = name == "jump" ? .jump : .slide
                press(action)
                flash(name == "jump" ? jumpButton : slideButton)
            }
        }
    }

    private func buildChrome() {
        scoreLabel.fontSize = 22
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 10

        centerBar.zPosition = 8
        barBackground.zPosition = -1
        barBackground.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        centerBar.addChild(barBackground)
        phaseLabel.fontSize = 20
        phaseLabel.fontColor = .white
        phaseLabel.verticalAlignmentMode = .center
        phaseLabel.horizontalAlignmentMode = .center
        phaseDetail.fontSize = 11
        phaseDetail.fontColor = UIColor(white: 1, alpha: 0.72)
        phaseDetail.verticalAlignmentMode = .center
        phaseDetail.horizontalAlignmentMode = .center
        countdownLabel.fontSize = 13
        countdownLabel.fontColor = UIColor(white: 1, alpha: 0.85)
        countdownLabel.verticalAlignmentMode = .center
        countdownLabel.horizontalAlignmentMode = .center
        centerBar.addChild(phaseLabel)
        centerBar.addChild(phaseDetail)
        centerBar.addChild(countdownLabel)
        centerBar.addChild(jumpButton)
        centerBar.addChild(slideButton)

        overlay.zPosition = 20
        let dim = SKSpriteNode(color: UIColor(white: 0, alpha: 0.55), size: .zero)
        dim.name = "dim"
        dim.anchorPoint = .zero
        dim.zPosition = 0
        overlay.addChild(dim)
        overlayTitle.fontSize = 42
        overlayTitle.fontColor = .white
        overlayTitle.zPosition = 1
        overlayBody.fontSize = 16
        overlayBody.fontColor = UIColor(white: 1, alpha: 0.86)
        overlayBody.numberOfLines = 0
        overlayBody.preferredMaxLayoutWidth = 280
        overlayBody.verticalAlignmentMode = .center
        overlayBody.horizontalAlignmentMode = .center
        overlayBody.zPosition = 1
        overlayTitle.verticalAlignmentMode = .center
        overlayTitle.horizontalAlignmentMode = .center
        overlay.addChild(overlayTitle)
        overlay.addChild(overlayBody)
    }

    private func layoutWorld() {
        guard size.width > 1, size.height > 1 else { return }
        let barHeight: CGFloat = 96
        let midY = size.height / 2
        let bottomHeight = max(0, midY - barHeight / 2)
        let topHeight = max(0, size.height - (midY + barHeight / 2))

        bottomPane.position = .zero
        bottomPane.resize(to: CGSize(width: size.width, height: bottomHeight), bottomInset: safeInsets.bottom)
        topPane.position = CGPoint(x: 0, y: midY + barHeight / 2)
        topPane.resize(to: CGSize(width: size.width, height: topHeight), bottomInset: 0)

        centerBar.position = CGPoint(x: size.width / 2, y: midY)
        barBackground.size = CGSize(width: size.width, height: barHeight)
        phaseLabel.position = CGPoint(x: 0, y: 18)
        countdownLabel.position = CGPoint(x: 0, y: 0)
        phaseDetail.position = CGPoint(x: 0, y: -18)
        phaseDetail.isHidden = size.width < 390
        let buttonInset: CGFloat = min(72, size.width * 0.18)
        jumpButton.position = CGPoint(x: -size.width / 2 + buttonInset, y: -2)
        slideButton.position = CGPoint(x: size.width / 2 - buttonInset, y: -2)

        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - safeInsets.top - 22)
        if let dim = overlay.childNode(withName: "dim") as? SKSpriteNode {
            dim.size = size
        }
        overlayTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        overlayBody.position = CGPoint(x: size.width / 2, y: size.height * 0.62 - 64)
        overlayBody.preferredMaxLayoutWidth = size.width - 48
    }

    private func showReady() {
        state = .ready
        lastUpdate = nil
        phase = .sync
        phaseRemaining = 16
        spawnRemaining = 1.25
        scriptedSpawns = 0
        distance = 0
        scoreLabel.text = "0 m"
        topPane.reset()
        bottomPane.reset()
        refreshPhaseLabel(announce: false)
        overlayTitle.text = "DualRun"
        overlayBody.text = "JUMP low blocks. SLIDE under bars.\nSYNC copies you. MIRROR flips the bottom runner."
        overlay.isHidden = false
    }

    private func startRun() {
        state = .playing
        overlay.isHidden = true
        lastUpdate = nil
    }

    private func finishRun(topHit: Bool, bottomHit: Bool) {
        state = .dead
        let who: String
        switch (topHit, bottomHit) {
        case (true, true): who = "Both runners crashed"
        case (true, false): who = "Top runner crashed"
        case (false, true): who = "Bottom runner crashed"
        case (false, false): who = "Crashed"
        }
        overlayTitle.text = "\(Int(distance / 14)) m"
        overlayBody.text = "\(who)\nTap to run again"
        overlay.isHidden = false
    }

    private func press(_ action: ControlAction) {
        switch phase {
        case .sync:
            topPane.apply(action)
            bottomPane.apply(action)
        case .mirror:
            topPane.apply(action)
            bottomPane.apply(action.opposite)
        }
    }

    private func spawnPair() {
        let kind: ObstacleKind
        if scriptedSpawns == 0 {
            kind = .low
        } else if scriptedSpawns == 1 {
            kind = .high
        } else {
            kind = Bool.random() ? .low : .high
        }
        scriptedSpawns += 1
        topPane.spawn(kind)
        switch phase {
        case .sync:
            bottomPane.spawn(kind)
        case .mirror:
            bottomPane.spawn(kind.opposite)
        }
    }

    private func refreshPhaseLabel(announce: Bool) {
        phaseLabel.text = phase.title
        phaseDetail.text = phase.detail
        countdownLabel.text = "\(max(0, Int(ceil(phaseRemaining))))s"
        phaseLabel.fontColor = phase == .sync
            ? UIColor(red: 0.55, green: 1, blue: 0.75, alpha: 1)
            : UIColor(red: 1, green: 0.84, blue: 0.42, alpha: 1)
        if announce {
            phaseLabel.setScale(1.25)
            phaseLabel.run(.scale(to: 1, duration: 0.22))
        }
    }

    private func controlName(at point: CGPoint) -> String? {
        for node in nodes(at: point) {
            var current: SKNode? = node
            while let candidate = current {
                if candidate.name == "jump" || candidate.name == "slide" {
                    return candidate.name
                }
                current = candidate.parent
            }
        }
        return nil
    }

    private func flash(_ button: ControlButton) {
        button.run(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.05),
            .fadeAlpha(to: 1, duration: 0.12)
        ]))
    }
}

private final class ControlButton: SKNode {
    init(name: String, title: String, color: UIColor) {
        super.init()
        self.name = name
        let plate = SKShapeNode(rectOf: CGSize(width: 96, height: 44), cornerRadius: 12)
        plate.name = name
        plate.fillColor = color.withAlphaComponent(0.22)
        plate.strokeColor = color
        plate.lineWidth = 2
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.name = name
        label.text = title
        label.fontSize = 16
        label.fontColor = color
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        addChild(plate)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }
}
