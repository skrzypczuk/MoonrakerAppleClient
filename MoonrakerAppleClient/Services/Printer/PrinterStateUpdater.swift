//
//  PrinterStateUpdater.swift
//  MoonrakerAppleClient
//
//  Created on 23/11/2024.
//

import Foundation

@MainActor
class PrinterStateUpdater {

    // MARK: - Update Methods

    func updateExtruder(
        state: inout PrinterState, name: String, temp: Double, target: Double, power: Double,
        canExtrude: Bool
    ) {
        guard let index = state.extruders.firstIndex(where: { $0.name == name }) else { return }
        state.extruders[index].temperature = temp
        state.extruders[index].target = target
        state.extruders[index].power = power
        state.extruders[index].canExtrude = canExtrude
    }

    func updateHeaterBed(state: inout PrinterState, temp: Double, target: Double, power: Double) {
        state.heaterBed.temperature = temp
        state.heaterBed.target = target
        state.heaterBed.power = power
    }

    func updateToolhead(
        state: inout PrinterState, position: [Axis: Double], homedAxes: [Axis: Bool]
    ) {
        state.toolhead.position = position
        state.toolhead.homedAxes = homedAxes
    }

    func updateGcodeMove(
        state: inout PrinterState, speedFactor: Double, speed: Double, extrudeFactor: Double
    ) {
        state.gcodeMove.speedFactor = speedFactor
        state.gcodeMove.speed = speed
        state.gcodeMove.extruderFactor = extrudeFactor
    }

    func updatePrintStats(
        state: inout PrinterState, filename: String, totalDuration: Double, printDuration: Double,
        stateString: String
    ) {
        state.printStats.filename = filename
        state.printStats.totalDuration = totalDuration
        state.printStats.printDuration = printDuration
        state.printStats.state = stateString

        // Update printer status based on state
        switch stateString {
        case "standby":
            state.printerStatus = .standby
        case "printing":
            state.printerStatus = .printing
        case "paused":
            state.printerStatus = .paused
        case "complete":
            state.printerStatus = .complete
        case "cancelled":
            state.printerStatus = .cancelled
        case "error":
            state.printerStatus = .error
        default:
            state.printerStatus = .null
        }
    }

    func updateFilamentFan(state: inout PrinterState, speed: Double, rpm: Int?) {
        state.filamentFan.speed = speed
        state.filamentFan.rpm = rpm
    }

    func updateTemperatureSensor(state: inout PrinterState, name: String, temp: Double) {
        guard let index = state.temperatureSensors.firstIndex(where: { $0.name == name }) else {
            return
        }
        state.temperatureSensors[index].temperature = temp
    }

    func updateTemperatureFan(
        state: inout PrinterState, name: String, speed: Double, temp: Double, target: Double
    ) {
        guard let index = state.temperatureFans.firstIndex(where: { $0.name == name }) else {
            return
        }
        state.temperatureFans[index].speed = speed
        state.temperatureFans[index].temperature = temp
        state.temperatureFans[index].target = target
    }

    func updateHeaterFan(state: inout PrinterState, name: String, speed: Double, rpm: Int?) {
        guard let index = state.heaterFans.firstIndex(where: { $0.name == name }) else { return }
        state.heaterFans[index].speed = speed
        state.heaterFans[index].rpm = rpm
    }
}
