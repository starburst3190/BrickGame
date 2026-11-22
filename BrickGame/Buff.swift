//
//  Buff.swift
//  BrickGame
//
//  Created by Jack on 2026/11/21.
//

import Foundation

enum BuffType {
    case longPaddle   // 板子變長（限時）
    case multiBall    // 多一顆球（直到掉下去）
    case bigBall      // 球變大（限時）
    case seeNumber    // 看得到磚塊上的數字（只能看到打中下一個磚塊之前）
}

func buff(for number: Int) -> BuffType? {
    if number == 6 {
        return .longPaddle
    } else if number == 7 {
        return .multiBall
    } else if number == 8 {
        return .bigBall
    } else if number == 10 {
        return .seeNumber
    } else {
        return nil
    }
}
