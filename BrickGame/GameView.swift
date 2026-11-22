//
//  GameView.swift
//  BrickGame
//
//  Created by Jack on 2026/11/14.
//

import SwiftUI

struct GameView: View {
    @State private var model = GameModel()
    @State private var dragStartX: CGFloat? = nil
    
    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(paused: model.state != .playing)) { context in
                ZStack {
                    ForEach(model.bricks) { brick in       // 磚塊
                        let lucky = model.showsNumber && buff(for: brick.number) != nil
                        let dimmed = model.showsNumber && !lucky

                        RoundedRectangle(cornerRadius: 4)
                            .fill(brickColor(row: brick.row, vivid: lucky))   // 幸運磚用飽和色
                            .frame(width: brick.rect.width, height: brick.rect.height)
                            .saturation(dimmed ? 0 : 1)
                            .opacity(dimmed ? 0.35 : 1)
//                            .overlay {
//                                if model.showsNumber {
//                                    Text("\(brick.number)")
//                                        .fontWeight(lucky ? .bold : .regular)
//                                }
//                            }
                            .position(x: brick.rect.midX, y: brick.rect.midY)
                            .transition(brickTransition(brick: brick, size: proxy.size))
                    }
                    
                    RoundedRectangle(cornerRadius: 32)       // 板子
                        .fill(.black)
                        .frame(width: model.paddleWidth, height: model.paddleHeight)
                        .position(x: model.paddleX, y: model.paddleY)
                    ForEach(model.balls) { ball in           // 球
                        Circle()
                            .fill(.red)
                            .frame(width: model.ballRadius * 2, height: model.ballRadius * 2)
                            .position(ball.pos)
                    }
                }
                .onChange(of: context.date) { oldDate, newDate in
                    model.update(dt: newDate.timeIntervalSince(oldDate))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStartX == nil {
                            dragStartX = model.paddleX
                        }
                        model.movePaddle(to: dragStartX! + value.translation.width)
                    }
                    .onEnded { _ in
                        dragStartX = nil
                    }
            )
            .overlay {
                if model.state == .ready {
                    VStack(spacing: 20) {
                        Picker("難度", selection: $model.difficulty) {
                            Text("簡單").tag(Difficulty.easy)
                            Text("困難").tag(Difficulty.hard)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                        Text(model.difficulty == .easy ?
                        """
                        簡單的關卡，建議初學者先玩這關，
                        熟悉操作與規則。
                        """
                             :
                        """
                        除了磚塊變多之外，球速也變快了呢...
                        享受挑戰吧！
                        """)
                        Button("開始") {
                            model.start()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .position(x: proxy.size.width / 2, y: model.panelY)
                } else if model.state == .won {
                    resultPanel(title: "過關！", color: .green)
                } else if model.state == .lost {
                    resultPanel(title: "失敗", color: .red)
                }
            }
            .overlay(alignment: .top) {
                if model.state == .playing {
                    HStack(spacing: 8) {
                        if model.longPaddleTime > 0 {
                            buffLabel("板子變長", time: model.longPaddleTime)
                        }
                        if model.bigBallTime > 0 {
                            buffLabel("球變大", time: model.bigBallTime)
                        }
                        if model.balls.count > 1 {
                            Text("球 ×\(model.balls.count)")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.yellow, in: Capsule())
                        }
                    }
                    .padding(.top, 24)
                    .allowsHitTesting(false)
                }
            }
            .overlay {
                if model.state == .playing && model.buffMessageTime > 0 {
                    Text(model.buffMessage)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.orange)
                        .shadow(radius: 4)
                        .offset(y: -40 * (1 - model.buffMessageTime))      // 慢慢往上飄
                        .opacity(min(1, model.buffMessageTime / 0.3))      // 最後 0.3 秒淡出
                        .allowsHitTesting(false)
                }
            }
            .sensoryFeedback(.success, trigger: model.buffCount)
            .onChange(of: model.difficulty) { oldValue, newValue in
                model.switchDifficulty(from: oldValue)
            }
            .onChange(of: proxy.size) { oldSize, newSize in
                model.setup(size: newSize)
            }
            .onAppear {
                model.setup(size: proxy.size)
            }
        }
        .frame(maxWidth: 500)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.88).ignoresSafeArea(edges: [.bottom, .leading, .trailing]))
        .background(Color.black.ignoresSafeArea(edges: .top))
        .preferredColorScheme(.light)
    }
    
    func brickColor(row: Int, vivid: Bool = false) -> Color {
        let r = row % 6
        var hue: Double
        if r == 0 {
            hue = 0.0      // 紅
        } else if r == 1 {
            hue = 0.08     // 橙
        } else if r == 2 {
            hue = 0.15     // 黃
        } else if r == 3 {
            hue = 0.35     // 綠
        } else if r == 4 {
            hue = 0.55     // 藍
        } else {
            hue = 0.78     // 紫
        }

        if vivid {
            return Color(hue: hue, saturation: 0.75, brightness: 0.95)   // 幸運磚：飽和一點
        } else {
            return Color(hue: hue, saturation: 0.35, brightness: 0.98)   // 平常：粉色系
        }
    }
    
    func brickTransition(brick: Brick, size: CGSize) -> AnyTransition {
        let anchor = UnitPoint(x: brick.rect.midX / size.width,
                               y: brick.rect.midY / size.height)
        return AnyTransition.scale(scale: 0.1, anchor: anchor).combined(with: .opacity)
    }
    
    func resultPanel(title: String, color: Color) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(color)
            Button("再玩一次") {
                model.restart()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    func buffLabel(_ name: String, time: Double) -> some View {
        Text("\(name) \(Int(time.rounded(.up)))s")
            .font(.subheadline.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.yellow, in: Capsule())
    }
}

#Preview {
    GameView()
}
