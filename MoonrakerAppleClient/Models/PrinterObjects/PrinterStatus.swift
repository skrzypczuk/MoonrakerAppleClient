//
//  PrinterStatus.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

enum PrinterStatus {
    case standby
    case printing
    case paused
    case complete
    case cancelled
    case error
    case null

    var description: String {
        switch self {
        case .standby:
            return "Standby"
        case .printing:
            return "Printing"
        case .paused:
            return "Paused"
        case .complete:
            return "Complete"
        case .cancelled:
            return "Cancelled"
        case .error:
            return "Error"
        case .null:
            return "null"
        }
    }
}
