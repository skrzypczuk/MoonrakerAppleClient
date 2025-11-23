//
//  HeaterBed.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

struct HeaterBed: Heater {
    var name: String = "heater_bed"
    var temperature: Double = 0.0
    var target: Double = 0.0
    var power: Double = 0.0
}
