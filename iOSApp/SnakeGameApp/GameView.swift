import AVFoundation
import SwiftUI

struct GameView: View {
    @AppStorage("snakeHighScore") private var highScore = 0

    @State private var engine = SnakeGameEngine(width: 20, height: 14)
    @State private var speedLevel = SpeedLevel.medium
    @State private var showingStartScreen = true
    @State private var timer = Timer.publish(every: SpeedLevel.medium.tickInterval, on: .main, in: .common).autoconnect()
    @StateObject private var soundPlayer = SoundPlayer()

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)

            ZStack {
                Color.gameBackground
                    .ignoresSafeArea()

                if showingStartScreen {
                    startScreen(metrics: metrics)
                } else {
                    VStack(spacing: metrics.sectionSpacing) {
                        header(fontSize: metrics.headerFontSize)
                            .frame(height: metrics.headerHeight)

                        board(lineWidth: metrics.boardLineWidth)
                            .aspectRatio(boardAspectRatio, contentMode: .fit)
                            .frame(maxWidth: metrics.boardWidth)
                            .frame(height: metrics.boardHeight)

                        controls(metrics: metrics)

                        gameActionButtons(fontSize: metrics.statusFontSize)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, metrics.topPadding)
                    .padding(.bottom, metrics.bottomPadding)
                }
            }
        }
        .foregroundStyle(.black)
        .onReceive(timer) { _ in
            guard !showingStartScreen else { return }

            let previousScore = engine.score
            let previousStatus = engine.status

            engine.tick()

            if engine.score > previousScore {
                updateHighScore()
                soundPlayer.play(.eat)
            }

            if previousStatus == .running && engine.status == .gameOver {
                soundPlayer.play(.gameOver)
            }
        }
    }

    private var boardAspectRatio: CGFloat {
        CGFloat(engine.width) / CGFloat(engine.height)
    }

    private func startScreen(metrics: LayoutMetrics) -> some View {
        VStack(spacing: metrics.startScreenSpacing) {
            Spacer(minLength: 0)

            VStack(spacing: metrics.highScoreTitleSpacing) {
                Text("REC \(formattedScore(highScore))")
                    .font(.system(size: metrics.headerFontSize, weight: .bold, design: .monospaced))

                Text("SNAKE")
                    .font(.system(size: metrics.titleFontSize, weight: .black, design: .monospaced))
            }

            VStack(spacing: 8) {
                Text("NIVEL")
                speedPicker(fontSize: metrics.statusFontSize)
            }
            .font(.system(size: metrics.headerFontSize, weight: .bold, design: .monospaced))

            VStack(spacing: 6) {
                Text("SETAS MEXEM")
                Text("NAO BATA")
            }
            .font(.system(size: metrics.statusFontSize, weight: .bold, design: .monospaced))

            Button("COMEÇAR") {
                startNewGame()
            }
            .font(.system(size: metrics.statusFontSize, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.gameBackground)
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(.black, in: Capsule())
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, metrics.topPadding)
        .padding(.bottom, metrics.bottomPadding)
    }

    private func speedPicker(fontSize: CGFloat) -> some View {
        HStack(spacing: 10) {
            ForEach(SpeedLevel.allCases) { level in
                Button(level.shortTitle) {
                    speedLevel = level
                    updateTimer()
                }
                .font(.system(size: fontSize, weight: .black, design: .monospaced))
                .foregroundStyle(speedLevel == level ? Color.gameBackground : .black)
                .frame(width: 40, height: 34)
                .background(speedLevel == level ? .black : Color.boardBackground, in: Capsule())
                .buttonStyle(.plain)
            }
        }
    }

    private func header(fontSize: CGFloat) -> some View {
        HStack {
            Text(String(format: "%04d", engine.score))
            Spacer()
            Text(speedLevel.shortTitle)
            Spacer()
            Text("REC \(formattedScore(highScore))")
        }
        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
        .padding(.horizontal, 12)
    }

    private func board(lineWidth: CGFloat) -> some View {
        GeometryReader { proxy in
            let cellSize = min(proxy.size.width / CGFloat(engine.width), proxy.size.height / CGFloat(engine.height))

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.boardBackground)

                Rectangle()
                    .stroke(.black, lineWidth: lineWidth)

                ForEach(Array(engine.snake.enumerated()), id: \.offset) { index, point in
                    Rectangle()
                        .fill(.black)
                        .frame(width: cellSize * 0.86, height: cellSize * 0.86)
                        .offset(x: CGFloat(point.x) * cellSize + cellSize * 0.07,
                                y: CGFloat(point.y) * cellSize + cellSize * 0.07)
                        .opacity(index == 0 ? 1 : 0.82)
                }

                Circle()
                    .fill(.black)
                    .frame(width: cellSize * 0.58, height: cellSize * 0.58)
                    .offset(x: CGFloat(engine.food.x) * cellSize + cellSize * 0.21,
                            y: CGFloat(engine.food.y) * cellSize + cellSize * 0.21)
            }
        }
    }

    private func controls(metrics: LayoutMetrics) -> some View {
        oneHandControls(size: metrics.controlsSize, buttonSize: metrics.controlButtonSize)
        .frame(height: metrics.controlAreaHeight)
    }

    private func oneHandControls(size: CGFloat, buttonSize: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: buttonSize * 0.34, height: buttonSize * 0.34)

            directionButton("▲", size: buttonSize) { engine.changeDirection(to: .up) }
                .offset(y: -size * 0.28)

            directionButton("▼", size: buttonSize) { engine.changeDirection(to: .down) }
                .offset(y: size * 0.28)

            directionButton("◀", size: buttonSize) { engine.changeDirection(to: .left) }
                .offset(x: -size * 0.28)

            directionButton("▶", size: buttonSize) { engine.changeDirection(to: .right) }
                .offset(x: size * 0.28)
        }
        .frame(width: size, height: size)
    }

    private func directionButton(_ title: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: size * 0.46, weight: .black, design: .monospaced))
                .foregroundStyle(Color.gameBackground)
                .frame(width: size, height: size)
                .background(.black, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func gameActionButtons(fontSize: CGFloat) -> some View {
        HStack(spacing: 12) {
            statusButton(fontSize: fontSize)
            menuButton(fontSize: fontSize)
        }
    }

    private func statusButton(fontSize: CGFloat) -> some View {
        Button(buttonTitle) {
            switch engine.status {
            case .ready, .gameOver:
                startNewGame()
            case .running:
                engine.pause()
            case .paused:
                engine.resume()
            }
        }
        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
        .foregroundStyle(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.boardBackground, in: Capsule())
        .buttonStyle(.plain)
    }

    private func menuButton(fontSize: CGFloat) -> some View {
        Button("MENU") {
            returnToMenu()
        }
        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
        .foregroundStyle(.black)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.boardBackground, in: Capsule())
        .buttonStyle(.plain)
    }

    private var buttonTitle: String {
        switch engine.status {
        case .ready:
            "COMEÇAR"
        case .running:
            "PAUSAR"
        case .paused:
            "CONTINUAR"
        case .gameOver:
            "FIM - RECOMEÇAR"
        }
    }

    private func startNewGame() {
        showingStartScreen = false
        updateTimer()
        engine.start()
    }

    private func returnToMenu() {
        engine.reset()
        showingStartScreen = true
    }

    private func updateTimer() {
        timer = Timer.publish(every: speedLevel.tickInterval, on: .main, in: .common).autoconnect()
    }

    private func updateHighScore() {
        guard engine.score > highScore else { return }
        highScore = engine.score
    }

    private func formattedScore(_ score: Int) -> String {
        String(format: "%04d", score)
    }
}

private enum SpeedLevel: Int, CaseIterable, Identifiable {
    case slow = 1
    case medium
    case fast

    var id: Int {
        rawValue
    }

    var shortTitle: String {
        "LV\(rawValue)"
    }

    var tickInterval: TimeInterval {
        switch self {
        case .slow:
            0.24
        case .medium:
            0.18
        case .fast:
            0.12
        }
    }
}

private struct LayoutMetrics {
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let sectionSpacing: CGFloat
    let headerHeight: CGFloat
    let headerFontSize: CGFloat
    let statusFontSize: CGFloat
    let controlButtonSize: CGFloat
    let controlsSize: CGFloat
    let controlAreaHeight: CGFloat
    let boardWidth: CGFloat
    let boardHeight: CGFloat
    let boardLineWidth: CGFloat
    let startScreenSpacing: CGFloat
    let highScoreTitleSpacing: CGFloat
    let titleFontSize: CGFloat

    init(size: CGSize, safeAreaInsets: EdgeInsets) {
        let width = size.width
        let height = size.height
        let compactHeight = height < 720
        let aspectRatio = CGFloat(20) / CGFloat(14)

        horizontalPadding = min(max(width * 0.055, 14), 30)
        topPadding = max(safeAreaInsets.top + (compactHeight ? 6 : 10), 14)
        bottomPadding = max(safeAreaInsets.bottom + (compactHeight ? 8 : 12), 14)
        sectionSpacing = compactHeight ? 10 : 16
        headerHeight = compactHeight ? 24 : 30
        headerFontSize = min(max(width * 0.045, 16), 22)
        statusFontSize = min(max(width * 0.038, 14), 18)
        controlsSize = min(max(width * 0.34, 124), compactHeight ? 138 : 156)
        controlButtonSize = controlsSize * 0.31
        controlAreaHeight = controlsSize
        boardLineWidth = min(max(width * 0.01, 3), 5)
        startScreenSpacing = compactHeight ? 14 : 22
        highScoreTitleSpacing = compactHeight ? 8 : 12
        titleFontSize = min(max(width * 0.15, 46), 72)

        let availableHeight = max(0, height - topPadding - bottomPadding)
        let statusHeight = statusFontSize + 18
        let reservedHeight = headerHeight + controlAreaHeight + statusHeight + (sectionSpacing * 3)
        let maxBoardHeight = max(150, availableHeight - reservedHeight)
        let maxBoardWidth = width - (horizontalPadding * 2)

        boardWidth = maxBoardWidth
        boardHeight = min(maxBoardWidth / aspectRatio, maxBoardHeight)
    }
}

private extension Color {
    static let gameBackground = Color(red: 0.78, green: 0.92, blue: 0.22)
    static let boardBackground = Color(red: 0.69, green: 0.84, blue: 0.16)
}

private final class SoundPlayer: ObservableObject {
    enum Effect: String, CaseIterable {
        case eat = "comeu"
        case gameOver = "fimdejogo"
    }

    private var players: [Effect: AVAudioPlayer] = [:]

    init() {
        for effect in Effect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") else {
                continue
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[effect] = player
            } catch {
                assertionFailure("Unable to load sound effect \(effect.rawValue).mp3")
            }
        }
    }

    func play(_ effect: Effect) {
        guard let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }
}
