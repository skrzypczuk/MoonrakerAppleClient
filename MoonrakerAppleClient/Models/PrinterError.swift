//
//  PrinterError.swift
//  MoonrakerAppleClient
//
//  Created by Mikolaj Skrzypczak on 14/01/2025.
//

import SwiftUI

struct PrinterError: Identifiable, Error {
    let id: UUID = UUID()
    let domain: String
    let message: String
}
