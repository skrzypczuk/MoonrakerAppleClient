//
//  GcodeMove.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

struct GcodeMove {
    var speedFactor: Double = 0.0
    var speed: Double = 0.0
    var extruderFactor: Double = 0.0
    var absoluteCoordinates: Bool = true
    var absoluteExtrude: Bool = false
    var homingOrigin: [Double] = [0.0, 0.0, 0.0, 0.0]
    var position: [Double] = [0.0, 0.0, 0.0, 0.0]
    var gcodePosition: [Double] = [0.0, 0.0, 0.0, 0.0]
}
