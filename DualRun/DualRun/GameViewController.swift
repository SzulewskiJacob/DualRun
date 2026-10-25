import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    private let skView = SKView()
    private var didPresentScene = false

    override func loadView() {
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 60
        skView.backgroundColor = .black
        view = skView
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let insets = view.safeAreaInsets
        if !didPresentScene, skView.bounds.width > 0, skView.bounds.height > 0 {
            let scene = GameScene(size: skView.bounds.size)
            scene.scaleMode = .resizeFill
            scene.safeInsets = insets
            skView.presentScene(scene)
            didPresentScene = true
        } else if let scene = skView.scene as? GameScene {
            scene.safeInsets = insets
        }
    }

    override var prefersStatusBarHidden: Bool { true }

    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
}
