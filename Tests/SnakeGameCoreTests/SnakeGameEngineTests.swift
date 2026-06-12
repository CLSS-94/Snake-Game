import Testing
@testable import SnakeGameCore

@Suite("Snake game engine")
struct SnakeGameEngineTests {
    @Test("starts centered and ready")
    func startsCenteredAndReady() {
        let engine = SnakeGameEngine(width: 12, height: 10)

        #expect(engine.status == .ready)
        #expect(engine.score == 0)
        #expect(engine.snake.count == 3)
        #expect(engine.head == Point(x: 6, y: 5))
    }

    @Test("moves one cell per tick")
    func movesOneCellPerTick() {
        var engine = SnakeGameEngine(width: 12, height: 10)
        engine.start()

        engine.tick()

        #expect(engine.head == Point(x: 7, y: 5))
        #expect(engine.snake.count == 3)
        #expect(engine.status == .running)
    }

    @Test("ignores immediate reverse direction")
    func ignoresImmediateReverseDirection() {
        var engine = SnakeGameEngine(width: 12, height: 10)
        engine.start()

        engine.changeDirection(to: .left)
        engine.tick()

        #expect(engine.head == Point(x: 7, y: 5))
    }

    @Test("ends game when hitting wall")
    func endsGameWhenHittingWall() {
        var engine = SnakeGameEngine(width: 8, height: 8)
        engine.start()

        for _ in 0..<5 {
            engine.tick()
        }

        #expect(engine.status == .gameOver)
    }
}
