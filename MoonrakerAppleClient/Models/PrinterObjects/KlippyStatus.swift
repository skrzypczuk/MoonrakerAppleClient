//
//  KlippyStatus.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

enum KlippyStatus {
    case ready
    case shutdown
    case disconnected
    case null

    var description: String {
        switch self {
        case .ready:
            return "Ready"
        case .shutdown:
            return "Shutdown"
        case .disconnected:
            return "Disconnected"
        case .null:
            return "null"
        }
    }
}
