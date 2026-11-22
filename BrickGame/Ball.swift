//
//  Ball.swift
//  BrickGame
//
//  Created by Jack on 2026/11/22.
//

import CoreGraphics
import Foundation

struct Ball: Identifiable {
    let id = UUID()
    var pos: CGPoint
    var velocity: CGVector
}
