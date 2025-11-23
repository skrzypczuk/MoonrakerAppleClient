//
//  Extruder.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

struct Extruder: Heater {
    var name: String = "extruder"
    var canExtrude: Bool = false
    var temperature: Double = 0.0
    var target: Double = 0.0
    var power: Double = 0.0
    var pressureAdvance: Double = 0.0
    var smoothTime: Double = 0.0
}
