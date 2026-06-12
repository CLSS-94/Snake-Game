import AVFoundation
import SwiftUI

struct GameView: View {
    @State private var engine = SnakeGameEngine(width: 20, height: 14)
    @State private var timer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()
    @StateObject private var soundPlayer = SoundPlayer()

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)

            ZStack {
                Color.gameBackground
                    .ignoresSafeArea()

                VStack(spacing: metrics.sectionSpacing) {
                    header(fontSize: metrics.headerFontSize)
                        .frame(height: metrics.headerHeight)

                    board(lineWidth: metrics.boardLineWidth)
                        .aspectRatio(boardAspectRatio, contentMode: .fit)
                        .frame(maxWidth: metrics.boardWidth)
                        .frame(height: metrics.boardHeight)

                    controls(buttonSize: metrics.controlButtonSize)

                    statusButton(fontSize: metrics.statusFontSize)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, metrics.topPadding)
                .padding(.bottom, metrics.bottomPadding)
            }
        }
        .foregroundStyle(.black)
        .onReceive(timer) { _ in
            let previousScore = engine.score
            let previousStatus = engine.status

            engine.tick()

            if engine.score > previousScore {
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

    private func header(fontSize: CGFloat) -> some View {
        HStack {
            Text(String(format: "%04d", engine.score))
            Spacer()
            Text("LEN \(engine.snake.count)")
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

    private func controls(buttonSize: CGFloat) -> some View {
        VStack(spacing: buttonSize * 0.16) {
            directionButton("▲", size: buttonSize) { engine.changeDirection(to: .up) }
            HStack(spacing: buttonSize * 0.75) {
                directionButton("◀", size: buttonSize) { engine.changeDirection(to: .left) }
                directionButton("▶", size: buttonSize) { engine.changeDirection(to: .right) }
            }
            directionButton("▼", size: buttonSize) { engine.changeDirection(to: .down) }
        }
    }

    private func directionButton(_ title: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: size * 0.44, weight: .black, design: .monospaced))
                .foregroundStyle(Color.gameBackground)
                .frame(width: size, height: size)
                .background(.black, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func statusButton(fontSize: CGFloat) -> some View {
        Button(buttonTitle) {
            switch engine.status {
            case .ready, .gameOver:
                engine.start()
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
    let boardWidth: CGFloat
    let boardHeight: CGFloat
    let boardLineWidth: CGFloat

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
        controlButtonSize = min(max(width * 0.105, 38), compactHeight ? 48 : 56)
        boardLineWidth = min(max(width * 0.01, 3), 5)

        let availableHeight = max(0, height - topPadding - bottomPadding)
        let controlsHeight = (controlButtonSize * 3) + (controlButtonSize * 0.32)
        let statusHeight = statusFontSize + 18
        let reservedHeight = headerHeight + controlsHeight + statusHeight + (sectionSpacing * 3)
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
