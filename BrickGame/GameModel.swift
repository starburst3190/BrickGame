//
//  GameModel.swift
//  BrickGame
//
//  Created by Jack on 2026/11/21.
//

import Foundation
import SwiftUI

enum GameState {
    case ready
    case playing
    case won
    case lost
}

let MAX_BRICK_NUMBER: Int = 20

@Observable
class GameModel {
    var areaSize: CGSize = .zero
    var difficulty: Difficulty = .easy
    var state: GameState = .ready
    var bricks: [Brick] = []
    
    // 開始畫面的 y：用困難模式（列數最多）的磚塊底部，切換難度時才不會跳
    var panelY: CGFloat {
        let rows = CGFloat(Difficulty.hard.rows)
        let hardBricksBottom = 80 + rows * 22 + (rows - 1) * 6   // 同 makeBricks 的 topOffset、brickHeight、gap
        return (hardBricksBottom + paddleY) / 2
    }
    
    // buff 秒數 / 剩餘秒數
    let buffDuration: Double = 10
    var longPaddleTime: Double = 0
    var bigBallTime: Double = 0
    
    // 是否透視數字
    var showsNumber = true
    
    // 拿到 buff 時的提示
    var buffMessage = ""
    var buffMessageTime: Double = 0
    var buffCount = 0          // 每拿到一次 buff 加 1，用來觸發震動
    
    // 板子
    var paddleX: CGFloat = 0
    var paddleWidth: CGFloat {
        if longPaddleTime > 0 {
            return 180
        } else {
            return 90
        }
    }
    let paddleHeight: CGFloat = 32
    var paddleY: CGFloat { areaSize.height - 80 }
    
    var bricksBottom: CGFloat {
        var bottom: CGFloat = 0
        for brick in bricks {
            if brick.rect.maxY > bottom {
                bottom = brick.rect.maxY
            }
        }
        return bottom
    }
    
    // 球
    var balls: [Ball] = []
    let maxBalls = 5
    var ballRadius: CGFloat {
        if bigBallTime > 0 {
            return 16
        } else {
            return 8
        }
    }
    
    // 切換難度時保留各難度的磚塊，切回來數字不變
    var savedBricks: [Difficulty: [Brick]] = [:]

    func switchDifficulty(from oldDifficulty: Difficulty) {
        savedBricks[oldDifficulty] = bricks
        if let saved = savedBricks[difficulty] {
            bricks = saved
        } else {
            bricks = makeBricks(difficulty: difficulty, areaWidth: areaSize.width)
        }
    }
        
    func setup(size: CGSize) {
        savedBricks = [:]
        showsNumber = true
        areaSize = size
        bricks = makeBricks(difficulty: difficulty, areaWidth: size.width)
        paddleX = size.width / 2
        resetBall()
    }
    
    func resetBall() {
        state = .ready
        longPaddleTime = 0
        bigBallTime = 0
        let pos = CGPoint(x: paddleX, y: paddleY - paddleHeight / 2 - ballRadius)
        balls = [Ball(pos: pos, velocity: .zero)]
    }
    
    func movePaddle(to x: CGFloat) {
        if state == .won || state == .lost { return }
        
        let half = paddleWidth / 2
        if x < half {
            paddleX = half
        } else if x > areaSize.width - half {
            paddleX = areaSize.width - half
        } else {
            paddleX = x
        }
        
        if state == .ready && !balls.isEmpty {
            balls[0].pos.x = paddleX
        }
    }
    
    func randomUpVelocity() -> CGVector {
        let angle = Double.random(in: 60...120) * .pi / 180
        let speed = difficulty.ballSpeed
        return CGVector(dx: speed * cos(angle), dy: -speed * sin(angle))
    }
    
    func start() {
        if state != .ready { return }
        balls[0].velocity = randomUpVelocity()
        state = .playing
    }
    
    func restart() {
        setup(size: areaSize)
    }
    
    func showBuffMessage(_ text: String) {
        buffMessage = text
        buffMessageTime = 1.0
        buffCount += 1
    }
    
    func applyBuff(_ buff: BuffType) {
        if buff == .longPaddle {
            longPaddleTime = buffDuration
            movePaddle(to: paddleX)
            showBuffMessage("板子變長！")
        } else if buff == .bigBall {
            bigBallTime = buffDuration
            showBuffMessage("球變大！")
        } else if buff == .multiBall {
            if balls.count < maxBalls {
                let pos = CGPoint(x: paddleX, y: paddleY - paddleHeight / 2 - ballRadius)
                balls.append(Ball(pos: pos, velocity: randomUpVelocity()))
                showBuffMessage("球變多！")
            }
        } else if buff == .seeNumber {
            showBuffMessage("透視！")
            showsNumber = true
        }
    }
    
    func hitBrick(at index: Int) {
        showsNumber = false
        // 幸運數字
        if let buff = buff(for: bricks[index].number) {
            applyBuff(buff)
        }
        
        for i in bricks.indices {
            bricks[i].number = Int.random(in: 1...MAX_BRICK_NUMBER)
        }
        withAnimation(.easeOut(duration: 0.4)) {
            _ = bricks.remove(at: index)
        }
    }
    
    func update(dt: Double) {
        if state != .playing { return }
        var dt = dt
        if dt > 1.0 / 30 { dt = 1.0 / 30 }
        
        // buff 倒數
        if buffMessageTime > 0 { buffMessageTime -= dt }
        if longPaddleTime > 0 { longPaddleTime -= dt }
        if bigBallTime > 0 { bigBallTime -= dt }
        
        for i in balls.indices {
            var ball = balls[i]
            ball.pos.x += ball.velocity.dx * dt
            ball.pos.y += ball.velocity.dy * dt
            
            // 碰到牆壁
            if ball.pos.x - ballRadius < 0 {
                ball.pos.x = ballRadius
                ball.velocity.dx = abs(ball.velocity.dx)
            } else if ball.pos.x + ballRadius > areaSize.width {
                ball.pos.x = areaSize.width - ballRadius
                ball.velocity.dx = -abs(ball.velocity.dx)
            }
            
            // 碰到板子
            let paddleTop = paddleY - paddleHeight / 2
            let half = paddleWidth / 2
            if ball.velocity.dy > 0
                && ball.pos.y + ballRadius >= paddleTop
                && ball.pos.y <= paddleY
                && ball.pos.x >= paddleX - half - ballRadius
                && ball.pos.x <= paddleX + half + ballRadius {
                
                // 撞擊位置：-1 是板子左端，0 是中間，1 是右端
                var offset = (ball.pos.x - paddleX) / half
                if offset < -1 {
                    offset = -1
                } else if offset > 1 {
                    offset = 1
                }
                
                let maxAngle = 60.0 * .pi / 180
                let angle = offset * maxAngle
                let speed = difficulty.ballSpeed
                ball.velocity = CGVector(dx: speed * sin(angle), dy: -speed * cos(angle))
                ball.pos.y = paddleTop - ballRadius
            }
            
            // 碰到磚塊
            let ballRect = CGRect(x: ball.pos.x - ballRadius, y: ball.pos.y - ballRadius,
                                  width: ballRadius * 2, height: ballRadius * 2)
            if let index = bricks.firstIndex(where: { $0.rect.intersects(ballRect) }) {
                let brickRect = bricks[index].rect
                let overlapX = min(ballRect.maxX, brickRect.maxX) - max(ballRect.minX, brickRect.minX)
                let overlapY = min(ballRect.maxY, brickRect.maxY) - max(ballRect.minY, brickRect.minY)
                
                if overlapX < overlapY {
                    // 撞到左右兩面
                    if ball.pos.x < brickRect.midX {
                        ball.velocity.dx = -abs(ball.velocity.dx)
                        ball.pos.x -= overlapX
                    } else {
                        ball.velocity.dx = abs(ball.velocity.dx)
                        ball.pos.x += overlapX
                    }
                } else {
                    // 撞到上下兩面
                    if ball.pos.y < brickRect.midY {
                        ball.velocity.dy = -abs(ball.velocity.dy)
                        ball.pos.y -= overlapY
                    } else {
                        ball.velocity.dy = abs(ball.velocity.dy)
                        ball.pos.y += overlapY
                    }
                }
                
                hitBrick(at: index)
            }
            
            // 碰到上方
            if ball.pos.y - ballRadius < 0 {
                ball.pos.y = ballRadius
                ball.velocity.dy = abs(ball.velocity.dy)
            }
            
            balls[i] = ball
        }
        
        // 移除掉出畫面的球，全部掉光才重置
        balls.removeAll { $0.pos.y - ballRadius > areaSize.height + 100 }
        
        if bricks.isEmpty {
            state = .won
        } else if balls.isEmpty {
            state = .lost
        }
    }
}

func makeBricks(difficulty: Difficulty, areaWidth: CGFloat) -> [Brick] {
    let sidePadding: CGFloat = 16
    let gap: CGFloat = 6
    let topOffset: CGFloat = 80
    let brickHeight: CGFloat = 22
    
    let cols = CGFloat(difficulty.cols)
    let brickWidth = (areaWidth - sidePadding * 2 - gap * (cols - 1)) / cols
    
    var result: [Brick] = []
    for row in 0..<difficulty.rows {
        for col in 0..<difficulty.cols {
            let x = sidePadding + CGFloat(col) * (brickWidth + gap)
            let y = topOffset + CGFloat(row) * (brickHeight + gap)
            let rect = CGRect(x: x, y: y, width: brickWidth, height: brickHeight)
            result.append(Brick(rect: rect, number: Int.random(in: 1...MAX_BRICK_NUMBER), row: row))
        }
    }
    return result
}
