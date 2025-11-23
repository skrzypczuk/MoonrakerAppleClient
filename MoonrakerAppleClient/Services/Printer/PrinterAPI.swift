//
//  PrinterApiHandling.swift
//  MoonrakerAppleClient
//
//  Created by Mikolaj Skrzypczak on 26/10/2024.
//

import AnyCodable
import Foundation

@MainActor
class PrinterAPI {
    private let service: PrinterService

    // dictionary: "methodName" -> handler block
    private var handlers: [String: (Any) -> Void] = [:]

    // Typed callbacks for status updates
    var onExtruderUpdate: ((String, Double, Double, Double, Bool) -> Void)?
    var onHeaterBedUpdate: ((Double, Double, Double) -> Void)?
    var onToolheadUpdate: (([Axis: Double], [Axis: Bool]) -> Void)?
    var onGcodeMoveUpdate: ((Double, Double, Double) -> Void)?
    var onPrintStatsUpdate: ((String, Double, Double, String) -> Void)?
    var onFilamentFanUpdate: ((Double, Int?) -> Void)?
    var onTemperatureSensorUpdate: ((String, Double) -> Void)?
    var onTemperatureFanUpdate: ((String, Double, Double, Double) -> Void)?
    var onHeaterFanUpdate: ((String, Double, Int?) -> Void)?

    init(service: PrinterService) {
        self.service = service
        service.onNotification = { [weak self] method, params in
            self?.handleNotification(method: method, params: params)
        }
    }

    func handleNotification(method: String, params: Any) {
        print("received notification: \(method)")

        switch method {
        case "notify_status_update":
            handleStatusUpdate(params)
        default:
            break
        }
    }

    func fetchPrinterInfo() async throws -> PrinterState {
        var printerState = PrinterState()
        do {
            guard
                let printerObjects = try await service.getRequest(method: "printer.objects.list")
                    .value
                    as? [String: Any]
            else {
                throw NSError(
                    domain: "PrinterClient", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot get printer objects"])
            }

            guard let objects = printerObjects["objects"] as? [String] else {
                throw PrinterError(domain: "API", message: "Invalid objects format")
            }
            printerState.printerObjects = objects
            for object in printerState.printerObjects {
                if object.hasPrefix("extruder") {
                    if !printerState.extruders.contains(where: { $0.name == object }) {
                        printerState.extruders.append(Extruder(name: object))
                    }
                } else if object.hasPrefix("temperature_sensor") {
                    let name = String(object.split(separator: " ")[1])
                    if !printerState.temperatureSensors.contains(where: { $0.name == name }) {
                        printerState.temperatureSensors.append(TemperatureSensor(name: name))
                    }
                } else if object.hasPrefix("temperature_fan") {
                    let name = String(object.split(separator: " ")[1])
                    if !printerState.temperatureFans.contains(where: { $0.name == name }) {
                        printerState.temperatureFans.append(TemperatureFan(name: name))
                    }
                } else if object.hasPrefix("heater_fan") {
                    let name = String(object.split(separator: " ")[1])
                    if !printerState.heaterFans.contains(where: { $0.name == name }) {
                        printerState.heaterFans.append(HeaterFan(name: name))
                    }
                } else if object.hasPrefix("gcode_macro") {
                    let name = String(object.split(separator: " ")[1])
                    if !printerState.gcodeMacros.contains(where: { $0 == name }) {
                        printerState.gcodeMacros.append(name)
                    }
                }
            }

            //get response as dictionary
            guard
                let printerInfo = try await service.getRequest(method: "printer.info").value
                    as? [String: Any]
            else {
                throw NSError(
                    domain: "PrinterClient", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot get printer info"])
            }
            //decode response to PrinterInfo
            let state: KlippyStatus = {
                switch printerInfo["state"] as? String {
                case "ready":
                    return .ready
                case "shutdown":
                    return .shutdown
                case "disconnected":
                    return .disconnected
                default:
                    return .null
                }
            }()

            printerState.klippyStatus = state
            printerState.stateMessage = printerInfo["state_message"] as? String ?? ""

            guard
                let storedGcodesResponse = try await service.getRequest(
                    method: "server.gcode_store", params: [Param(key: "count", values: 100)]
                ).value as? [String: Any]
            else {
                throw NSError(
                    domain: "PrinterClient", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Cannot get stored gcodes"])
            }
            if let storedGcodes = storedGcodesResponse["gcode_store"] as? [[String: Any]] {

                for gcode in storedGcodes {
                    guard let message = gcode["message"] as? String,
                        let time = gcode["time"] as? Double,
                        let type = gcode["type"] as? String
                    else { continue }

                    let gcode = GCode(
                        message: message, time: time, type: type == "command" ? .command : .response
                    )
                    printerState.gcodes.append(gcode)
                }
            }

            return printerState

        } catch {
            throw error
        }
    }
    func statusUpdateSubscribe(printerObjects: [String]) async {
        do {
            var objectsToSubscribe: [String] = []
            // Adding keys
            objectsToSubscribe.append("toolhead")
            objectsToSubscribe.append("gcode_move")

            if printerObjects.contains("virtual_sdcard") {
                objectsToSubscribe.append("print_stats")
            }
            if printerObjects.contains("display")
                || printerObjects.contains("display_status")
            {
                objectsToSubscribe.append("display_status")
            }
            if printerObjects.contains("heater_bed") {
                objectsToSubscribe.append("heater_bed")
            }
            if printerObjects.contains("fan") {
                objectsToSubscribe.append("fan")
            }
            for object in printerObjects.filter({ $0.hasPrefix("extruder") }) {
                objectsToSubscribe.append(object)
            }
            for object in printerObjects.filter({ $0.hasPrefix("temperature_fan") }) {
                objectsToSubscribe.append(object)
            }
            for object in printerObjects.filter({ $0.hasPrefix("temperature_sensor") }) {
                objectsToSubscribe.append(object)
            }
            for object in printerObjects.filter({ $0.hasPrefix("heater_fan") }) {
                objectsToSubscribe.append(object)
            }

            _ = try await service.getRequest(
                method: "printer.objects.subscribe",
                params: [
                    Param(
                        key: "objects",
                        //convert to [String: nil]
                        values: Dictionary(
                            uniqueKeysWithValues: objectsToSubscribe.map { ($0, nil as Any?) })
                    )
                ]
            )
            // TODO: Handle subscription response and update state
        } catch {
            print(error)
        }
    }

    func handleStatusUpdate(_ notification: Any?) {
        guard let response = notification as? [Any],
            let objects = response.first as? [String: Any]
        else {
            return
        }

        // Parse and notify with typed data
        for (key, value) in objects {
            guard let objectData = value as? [String: Any] else { continue }

            switch key {
            case let k where k.hasPrefix("extruder"):
                parseExtruderUpdate(name: k, data: objectData)

            case let k where k.hasPrefix("temperature_sensor"):
                let name = String(k.split(separator: " ")[1])
                parseTemperatureSensorUpdate(name: name, data: objectData)

            case let k where k.hasPrefix("temperature_fan"):
                let name = String(k.split(separator: " ")[1])
                parseTemperatureFanUpdate(name: name, data: objectData)

            case let k where k.hasPrefix("heater_fan"):
                let name = String(k.split(separator: " ")[1])
                parseHeaterFanUpdate(name: name, data: objectData)

            case "heater_bed":
                parseHeaterBedUpdate(data: objectData)

            case "toolhead":
                parseToolheadUpdate(data: objectData)

            case "gcode_move":
                parseGcodeMoveUpdate(data: objectData)

            case "print_stats":
                parsePrintStatsUpdate(data: objectData)

            case "fan":
                parseFilamentFanUpdate(data: objectData)

            default:
                break
            }
        }
    }

    // MARK: - Parse Methods

    private func parseExtruderUpdate(name: String, data: [String: Any]) {
        let temp = data["temperature"].map { getDoubleValue($0) } ?? 0.0
        let target = data["target"].map { getDoubleValue($0) } ?? 0.0
        let power = data["power"].map { getDoubleValue($0) } ?? 0.0
        let canExtrude = data["can_extrude"] as? Bool ?? false

        onExtruderUpdate?(name, temp, target, power, canExtrude)
    }

    private func parseHeaterBedUpdate(data: [String: Any]) {
        let temp = data["temperature"].map { getDoubleValue($0) } ?? 0.0
        let target = data["target"].map { getDoubleValue($0) } ?? 0.0
        let power = data["power"].map { getDoubleValue($0) } ?? 0.0

        onHeaterBedUpdate?(temp, target, power)
    }

    private func parseToolheadUpdate(data: [String: Any]) {
        var position: [Axis: Double] = [:]
        var homedAxes: [Axis: Bool] = [.x: false, .y: false, .z: false]

        if let posArray = data["position"] as? [Any] {
            let doubles = convertToDoubleArray(posArray)
            if doubles.count >= 4 {
                position[.x] = doubles[0]
                position[.y] = doubles[1]
                position[.z] = doubles[2]
                position[.e] = doubles[3]
            }
        }

        if let homedAxesString = data["homed_axes"] as? String {
            homedAxes[.x] = homedAxesString.contains("x")
            homedAxes[.y] = homedAxesString.contains("y")
            homedAxes[.z] = homedAxesString.contains("z")
        }

        onToolheadUpdate?(position, homedAxes)
    }

    private func parseGcodeMoveUpdate(data: [String: Any]) {
        let speedFactor = data["speed_factor"].map { getDoubleValue($0) } ?? 1.0
        let speed = data["speed"].map { getDoubleValue($0) } ?? 0.0
        let extrudeFactor = data["extrude_factor"].map { getDoubleValue($0) } ?? 1.0

        onGcodeMoveUpdate?(speedFactor, speed, extrudeFactor)
    }

    private func parsePrintStatsUpdate(data: [String: Any]) {
        let filename = data["filename"] as? String ?? ""
        let totalDuration = data["total_duration"].map { getDoubleValue($0) } ?? 0.0
        let printDuration = data["print_duration"].map { getDoubleValue($0) } ?? 0.0
        let state = data["state"] as? String ?? ""

        onPrintStatsUpdate?(filename, totalDuration, printDuration, state)
    }

    private func parseFilamentFanUpdate(data: [String: Any]) {
        let speed = data["speed"].map { getDoubleValue($0) } ?? 0.0
        let rpm = data["rpm"] as? Int

        onFilamentFanUpdate?(speed, rpm)
    }

    private func parseTemperatureSensorUpdate(name: String, data: [String: Any]) {
        let temp = data["temperature"].map { getDoubleValue($0) } ?? 0.0

        onTemperatureSensorUpdate?(name, temp)
    }

    private func parseTemperatureFanUpdate(name: String, data: [String: Any]) {
        let speed = data["speed"].map { getDoubleValue($0) } ?? 0.0
        let temp = data["temperature"].map { getDoubleValue($0) } ?? 0.0
        let target = data["target"].map { getDoubleValue($0) } ?? 0.0

        onTemperatureFanUpdate?(name, speed, temp, target)
    }

    private func parseHeaterFanUpdate(name: String, data: [String: Any]) {
        let speed = data["speed"].map { getDoubleValue($0) } ?? 0.0
        let rpm = data["rpm"] as? Int

        onHeaterFanUpdate?(name, speed, rpm)
    }

    // MARK: - Helper Methods

    private func getDoubleValue(_ value: Any?) -> Double {
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let intValue = value as? Int {
            return Double(intValue)
        }
        return 0.0
    }

    private func convertToDoubleArray(_ input: [Any]) -> [Double] {
        return input.compactMap { element in
            if let doubleValue = element as? Double {
                return doubleValue
            } else if let intValue = element as? Int {
                return Double(intValue)
            }
            return nil
        }
    }
}
