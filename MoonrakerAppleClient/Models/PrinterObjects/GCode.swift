//
//  GCode.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

struct GCode: Identifiable {
    var id = UUID()
    let message: String
    let time: Double
    let type: GCodeType

    enum GCodeType {
        case command
        case response

        var rawValue: String {
            switch self {
            case .command:
                return "Command"
            case .response:
                return "Response"
            }
        }
    }
}
