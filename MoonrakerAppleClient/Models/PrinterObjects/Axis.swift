//
//  Axis.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

enum Axis {
    case x
    case y
    case z
    case e
    case xyz

    var description: String {
        switch self {
        case .x:
            return "X"
        case .y:
            return "Y"
        case .z:
            return "Z"
        case .e:
            return "E"
        case .xyz:
            return "XYZ"
        }
    }
}
