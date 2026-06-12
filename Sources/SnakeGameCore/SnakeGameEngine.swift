public struct SnakeGameEngine: Sendable {
    public private(set) var width: Int
    public private(set) var height: Int
    public private(set) var snake: [Point]
    public private(set) var food: Point
    public private(set) var score: Int
    public private(set) var status: GameStatus
    public private(set) var direction: Direction

    private let initialSnake: [Point]

    public var head: Point {
        snake[0]
    }

    public init(width: Int = 20, height: Int = 14) {
        precondition(width >= 8, "The board width must be at least 8 cells.")
        precondition(height >= 8, "The board height must be at least 8 cells.")

        self.width = width
        self.height = height
        self.direction = .right
        self.score = 0
        self.status = .ready

        let start = Point(x: width / 2, y: height / 2)
        self.initialSnake = [
            start,
            Point(x: start.x - 1, y: start.y),
            Point(x: start.x - 2, y: start.y)
        ]
        self.snake = initialSnake
        self.food = Point(x: min(width - 2, start.x + 4), y: start.y)
    }

    public mutating func start() {
        if status == .ready || status == .gameOver {
            reset()
        }
        status = .running
    }

    public mutating func pause() {
        guard status == .running else { return }
        status = .paused
    }

    public mutating func resume() {
        guard status == .paused else { return }
        status = .running
    }

    public mutating func reset() {
        snake = initialSnake
        direction = .right
        score = 0
        status = .ready
        food = nextFoodCandidate(avoiding: snake, seed: score)
    }

    public mutating func changeDirection(to newDirection: Direction) {
        guard !newDirection.isOpposite(of: direction) else { return }
        direction = newDirection
        if status == .ready {
            status = .running
        }
    }

    @discardableResult
    public mutating func tick() -> GameStatus {
        guard status == .running else { return status }

        let newHead = head + direction.delta
        guard isInsideBoard(newHead), !snake.dropLast().contains(newHead) else {
            status = .gameOver
            return status
        }

        snake.insert(newHead, at: 0)
        if newHead == food {
            score += 10
            food = nextFoodCandidate(avoiding: snake, seed: score + snake.count)
        } else {
            snake.removeLast()
        }

        return status
    }

    public func isInsideBoard(_ point: Point) -> Bool {
        point.x >= 0 && point.y >= 0 && point.x < width && point.y < height
    }

    private func nextFoodCandidate(avoiding blockedCells: [Point], seed: Int) -> Point {
        let blocked = Set(blockedCells)
        let totalCells = width * height
        var index = abs(seed * 31 + 7) % totalCells

        for _ in 0..<totalCells {
            let point = Point(x: index % width, y: index / width)
            if !blocked.contains(point) {
                return point
            }
            index = (index + 1) % totalCells
        }

        return Point(x: 0, y: 0)
    }
}
