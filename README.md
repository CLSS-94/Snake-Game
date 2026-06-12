# Snake Game iOS

Este repositório é um ponto de partida para criar um jogo da cobrinha simples para iOS, inspirado no **Snake II dos celulares Nokia**. Conhecido pelo visual verde monocromático, placar no topo, borda retangular e comandos direcionais.

## O que já existe aqui

- `Sources/SnakeGameCore`: regras do jogo em Swift puro, separadas da interface para facilitar testes.
- `Tests/SnakeGameCoreTests`: testes automatizados da movimentação, colisão e estado inicial.
- `iOSApp/SnakeGameApp`: telas SwiftUI para projeto iOS no Xcode.
- `Package.swift`: pacote Swift usado para validar a lógica principal fora do Xcode.

## Como abrir e testar no Xcode

> Para compilar e rodar no iPhone ou simulador iOS, você precisa de um Mac com Xcode instalado.

1. Abra `iOSApp/SnakeGame.xcodeproj` no Xcode.
2. Escolha a scheme `SnakeGame`.
3. Selecione um simulador de iPhone.
4. Aperte **Run**.

## Próximas melhorias sugeridas

- Sons curtos ao comer comida e ao perder.
- Níveis de velocidade.
- Tela inicial com instruções.
- Persistência do recorde usando `UserDefaults`.
- Controles por swipe, além dos botões.
