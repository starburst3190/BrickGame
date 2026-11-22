//
//  Brick.swift
//  BrickGame
//
//  Created by Jack on 2026/11/21.
//

import Foundation

struct Brick : Identifiable {
    let id = UUID()
    let rect : CGRect
    var number : Int
    let row : Int
}
