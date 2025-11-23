//
//  Heater.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

protocol Heater {
    var name: String { get set }
    var temperature: Double { get set }
    var target: Double { get set }
    var power: Double { get set }
}
