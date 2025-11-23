//
//  PrinterState.swift
//  MoonrakerAppleClient
//
//  Created by Mikolaj Skrzypczak on 10/11/2024.
//

import Foundation

/// Main state container for all printer information
struct PrinterState {
    var klippyStatus: KlippyStatus = .null
    var printerStatus: PrinterStatus = .null
    var stateMessage: String = "null"

    var printerObjects: [String] = []

    var gcodes: [GCode] = []
    var extruders: [Extruder] = []
    var heaterBed: HeaterBed = HeaterBed()
    var toolhead: Toolhead = Toolhead()
    var printStats: PrintStats = PrintStats()
    var gcodeMove: GcodeMove = GcodeMove()
    var filamentFan: FilamentFan = FilamentFan()
    var temperatureSensors: [TemperatureSensor] = []
    var temperatureFans: [TemperatureFan] = []
    var heaterFans: [HeaterFan] = []
    var gcodeMacros: [String] = []
}
