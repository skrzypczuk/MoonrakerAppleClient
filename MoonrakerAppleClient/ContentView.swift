//
//  ContentView.swift
//  MoonrakerAppleClient
//
//  Created by Mikolaj Skrzypczak on 16/10/2024.
//

import AnyCodable
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var printer: PrinterViewModel
    var body: some View {
        VStack {
            Text(printer.printerState.stateMessage)

            Button(action: {
                Task {
                    await printer.fetchInfo()
                }
            }) {
                Text("Fetch")
            }
            Button("Home") {
                Task {
                    await printer.homeX()
                }
            }
        }
    }
}
