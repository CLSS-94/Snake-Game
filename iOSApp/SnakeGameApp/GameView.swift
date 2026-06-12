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

                        gameActionButtons(metrics: metrics)
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
            Spacer(minLength: metrics.startScreenEdgeSpacing)

            VStack(spacing: metrics.highScoreTitleSpacing) {
                Text("REC \(formattedScore(highScore))")
                    .font(.system(size: metrics.headerFontSize, weight: .bold, design: .monospaced))

                Text("SNAKE")
                    .font(.system(size: metrics.titleFontSize, weight: .black, design: .monospaced))
            }

            VStack(spacing: 8) {
                Text("NIVEL")
                speedPicker(metrics: metrics)
            }
            .font(.system(size: metrics.headerFontSize, weight: .bold, design: .monospaced))

            VStack(spacing: 6) {
                Text("SETAS MEXEM")
                Text("NAO BATA")
            }
            .font(.system(size: metrics.statusFontSize, weight: .bold, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.85)

            Button("COMEÇAR") {
                startNewGame()
            }
            .font(.system(size: metrics.statusFontSize, weight: .bold, design: .monospaced))
            .foregroundStyle(Color.gameBackground)
            .frame(minWidth: metrics.primaryButtonMinWidth, minHeight: metrics.actionButtonHeight)
            .padding(.horizontal, 18)
            .background(.black, in: Capsule())
            .buttonStyle(.plain)

            Spacer(minLength: metrics.startScreenEdgeSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, metrics.horizontalPadding)
        .padding(.top, metrics.topPadding)
        .padding(.bottom, metrics.bottomPadding)
    }

    private func speedPicker(metrics: LayoutMetrics) -> some View {
        HStack(spacing: metrics.pickerSpacing) {
            ForEach(SpeedLevel.allCases) { level in
                Button(level.shortTitle) {
                    speedLevel = level
                    updateTimer()
                }
                .font(.system(size: metrics.statusFontSize, weight: .black, design: .monospaced))
                .foregroundStyle(speedLevel == level ? Color.gameBackground : .black)
                .frame(width: metrics.pickerButtonWidth, height: metrics.pickerButtonHeight)
                .background(speedLevel == level ? .black : Color.boardBackground, in: Capsule())
                .buttonStyle(.plain)
            }
        }
    }

    private func header(fontSize: CGFloat) -> some View {
        HStack {
            Text(String(format: "%04d", engine.score))
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Text(speedLevel.shortTitle)
                .frame(width: 44, alignment: .center)
            Spacer()
            Text("REC \(formattedScore(highScore))")
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
        .lineLimit(1)
        .minimumScaleFactor(0.78)
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

                if engine.status == .gameOver {
                    Rectangle()
                        .fill(.black.opacity(0.08))
                        .frame(width: proxy.size.width, height: proxy.size.height)

                    gameOverPanel(width: proxy.size.width)
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            }
        }
    }

    private func gameOverPanel(width: CGFloat) -> some View {
        let panelWidth = min(width * 0.72, 240)
        let titleFontSize = min(max(width * 0.11, 28), 42)
        let detailFontSize = min(max(width * 0.038, 14), 18)

        return VStack(spacing: 7) {
            Text("FIM")
                .font(.system(size: titleFontSize, weight: .black, design: .monospaced))

            HStack(spacing: 12) {
                Text("PTS \(formattedScore(engine.score))")
                Text("REC \(formattedScore(highScore))")
            }
            .font(.system(size: detailFontSize, weight: .bold, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
        .foregroundStyle(Color.gameBackground)
        .frame(width: panelWidth)
        .padding(.vertical, 10)
        .background(.black.opacity(0.92), in: RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.gameBackground, lineWidth: 2)
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

    private func gameActionButtons(metrics: LayoutMetrics) -> some View {
        HStack(spacing: metrics.actionButtonSpacing) {
            statusButton(metrics: metrics)
            menuButton(metrics: metrics)
        }
        .frame(maxWidth: metrics.boardWidth)
    }

    private func statusButton(metrics: LayoutMetrics) -> some View {
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
        .font(.system(size: metrics.statusFontSize, weight: .bold, design: .monospaced))
        .foregroundStyle(.black)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .frame(maxWidth: .infinity, minHeight: metrics.actionButtonHeight)
        .padding(.horizontal, 10)
        .background(Color.boardBackground, in: Capsule())
        .buttonStyle(.plain)
    }

    private func menuButton(metrics: LayoutMetrics) -> some View {
        Button("MENU") {
            returnToMenu()
        }
        .font(.system(size: metrics.statusFontSize, weight: .bold, design: .monospaced))
        .foregroundStyle(.black)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .frame(width: metrics.menuButtonWidth, height: metrics.actionButtonHeight)
        .padding(.horizontal, 8)
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
            "RECOMEÇAR"
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
    let pickerSpacing: CGFloat
    let pickerButtonWidth: CGFloat
    let pickerButtonHeight: CGFloat
    let controlButtonSize: CGFloat
    let controlsSize: CGFloat
    let controlAreaHeight: CGFloat
    let actionButtonHeight: CGFloat
    let actionButtonSpacing: CGFloat
    let menuButtonWidth: CGFloat
    let primaryButtonMinWidth: CGFloat
    let boardWidth: CGFloat
    let boardHeight: CGFloat
    let boardLineWidth: CGFloat
    let startScreenSpacing: CGFloat
    let startScreenEdgeSpacing: CGFloat
    let highScoreTitleSpacing: CGFloat
    let titleFontSize: CGFloat

    init(size: CGSize, safeAreaInsets: EdgeInsets) {
        let width = size.width
        let height = size.height
        let compactHeight = height < 720
        let tallHeight = height > 880
        let aspectRatio = CGFloat(20) / CGFloat(14)

        horizontalPadding = min(max(width * 0.055, 14), 30)
        topPadding = max(safeAreaInsets.top + (compactHeight ? 4 : 10), 12)
        bottomPadding = max(safeAreaInsets.bottom + (compactHeight ? 6 : 12), 12)
        sectionSpacing = compactHeight ? 8 : (tallHeight ? 18 : 14)
        headerHeight = compactHeight ? 24 : 30
        headerFontSize = min(max(width * 0.045, 16), 22)
        statusFontSize = min(max(width * 0.038, 14), 18)
        pickerSpacing = compactHeight ? 8 : 10
        pickerButtonWidth = min(max(width * 0.1, 38), 44)
        pickerButtonHeight = min(max(width * 0.082, 32), 36)
        controlsSize = min(max(width * 0.33, 118), compactHeight ? 132 : 152)
        controlButtonSize = controlsSize * 0.31
        controlAreaHeight = controlsSize
        actionButtonHeight = compactHeight ? 34 : 38
        actionButtonSpacing = compactHeight ? 8 : 12
        menuButtonWidth = compactHeight ? 68 : 74
        primaryButtonMinWidth = compactHeight ? 112 : 124
        boardLineWidth = min(max(width * 0.01, 3), 5)
        startScreenSpacing = compactHeight ? 12 : (tallHeight ? 24 : 20)
        startScreenEdgeSpacing = compactHeight ? 8 : 18
        highScoreTitleSpacing = compactHeight ? 8 : 12
        titleFontSize = min(max(width * 0.15, 46), 72)

        let availableHeight = max(0, height - topPadding - bottomPadding)
        let statusHeight = actionButtonHeight
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
