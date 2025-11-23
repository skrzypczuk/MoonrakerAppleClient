//
//  Toolhead.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

struct Toolhead {
    var extruder: String = ""
    var position: [Axis: Double] = [.x: 0.0, .y: 0.0, .z: 0.0, .e: 0.0]
    var maxVelocity: Double = 0.0
    var maxAccel: Double = 0.0
    var maxAccelToDecel: Double = 0.0
    var squareCornerVelocity: Double = 0.0
    var homedAxes: [Axis: Bool] = [.x: false, .y: false, .z: false]
}
