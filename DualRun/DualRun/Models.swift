import CoreGraphics

enum ControlAction {
    case jump
    case slide

    var opposite: ControlAction {
        switch self {
        case .jump: return .slide
        case .slide: return .jump
        }
    }
}

enum ObstacleKind {
    case low
    case high

    var opposite: ObstacleKind {
        switch self {
        case .low: return .high
        case .high: return .low
        }
    }
}

enum ControlPhase {
    case sync
    case mirror

    var title: String {
        switch self {
        case .sync: return "SYNC"
        case .mirror: return "MIRROR"
        }
    }

    var detail: String {
        switch self {
        case .sync: return "matched"
        case .mirror: return "flipped"
        }
    }

    var opposite: ControlPhase {
        switch self {
        case .sync: return .mirror
        case .mirror: return .sync
        }
    }
}

struct HitBox {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    func intersects(_ other: HitBox, inset: CGFloat) -> Bool {
        let left = x + inset
        let right = x + width - inset
        let bottom = y + inset
        let top = y + height - inset
        let otherLeft = other.x + inset
        let otherRight = other.x + other.width - inset
        let otherBottom = other.y + inset
        let otherTop = other.y + other.height - inset
        return left < otherRight && right > otherLeft && bottom < otherTop && top > otherBottom
    }
}
