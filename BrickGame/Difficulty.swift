//
//  Difficulty.swift
//  BrickGame
//
//  Created by Jack on 2026/11/21.
//

import Foundation

enum Difficulty {
    case easy, hard

    var rows: Int {
        switch self {
        case .easy: return 4
        case .hard: return 8
        }
    }

    var cols: Int {
        switch self {
        case .easy: return 6
        case .hard: return 10
        }
    }

    var ballSpeed: CGFloat {      // 每秒移動幾個 point
        switch self {
        case .easy: return 300
        case .hard: return 420
        }
    }
}
