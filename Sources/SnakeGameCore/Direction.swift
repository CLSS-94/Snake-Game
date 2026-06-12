public enum Direction: Equatable, Sendable {
    case up
    case down
    case left
    case right

    public var delta: Point {
        switch self {
        case .up:
            Point(x: 0, y: -1)
        case .down:
            Point(x: 0, y: 1)
        case .left:
            Point(x: -1, y: 0)
        case .right:
            Point(x: 1, y: 0)
        }
    }

    public func isOpposite(of other: Direction) -> Bool {
        switch (self, other) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            true
        default:
            false
        }
    }
}
