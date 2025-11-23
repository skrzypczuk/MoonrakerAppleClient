//
//  PrintStats.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

struct PrintStats {
    var filename: String = ""
    var totalDuration: Double = 0.0
    var printDuration: Double = 0.0
    var filamentUsed: Double = 0.0
    var state: String = ""
    var message: String = ""
    var info: [String: Any?] = ["totalLayer": nil, "currentLayer": nil]
}
