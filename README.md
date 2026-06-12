# Snake Game iOS

Este repositório é um ponto de partida para criar um jogo da cobrinha simples para iOS, inspirado no **Snake II dos celulares Nokia**. Conhecido pelo visual verde monocromático, placar no topo, borda retangular e comandos direcionais.

## O que já existe aqui

- `Sources/SnakeGameCore`: regras do jogo em Swift puro, separadas da interface para facilitar testes.
- `Tests/SnakeGameCoreTests`: testes automatizados da movimentação, colisão e estado inicial.
- `iOSApp/SnakeGameApp`: app iOS em SwiftUI, com visual verde monocromático inspirado no Snake clássico.
- `iOSApp/SnakeGameApp/Resources`: efeitos sonoros usados ao comer comida e ao perder.
- `Package.swift`: pacote Swift usado para validar a lógica principal fora do Xcode.

## Funcionalidades

- Tela inicial simples com seleção de nível.
- Três velocidades: `LV1`, `LV2` e `LV3`.
- Placar e recorde persistido localmente com `UserDefaults`.
- Efeito sonoro ao comer comida.
- Efeito sonoro ao encerrar o jogo.
- Botões direcionais na tela.
- Botões para pausar/continuar e voltar ao menu.
- Layout adaptável para diferentes tamanhos de iPhone.
- Tela de fim de jogo com resumo curto de pontos e recorde.

## Como abrir e testar no Xcode

> Para compilar e rodar no iPhone ou simulador iOS, você precisa de um Mac com Xcode instalado.

1. Abra `iOSApp/SnakeGame.xcodeproj` no Xcode.
2. Escolha a scheme `SnakeGame`.
3. Selecione um simulador de iPhone.
4. Aperte **Run**.

## Próximas melhorias sugeridas

- Controles por swipe, além dos botões.
