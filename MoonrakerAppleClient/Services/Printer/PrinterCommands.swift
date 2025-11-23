import Foundation

@MainActor
class PrinterCommands {
    private let service: PrinterService

    init(service: PrinterService) {
        self.service = service
    }

    // MARK: - GCode Execution

    func runGCode(_ gcode: String) async throws {
        try await service.sendRequest(
            method: "printer.gcode.script", params: [Param(key: "script", values: gcode)])
    }

    // MARK: - Temperature Commands

    func setHeaterTarget(_ heaterName: String, to target: Double) async throws {
        try await runGCode("SET_HEATER_TEMPERATURE HEATER=\(heaterName) TARGET=\(target)")
    }

    func turnOffHeaters() async throws {
        try await runGCode("TURN_OFF_HEATERS")
    }

    // MARK: - Tool Commands

    func homeAxis(_ axis: Axis) async throws {
        if axis == .xyz {
            try await runGCode("G28")
        } else {
            try await runGCode("G28 \(axis.description)")
        }
    }

    func moveAxisToPosition(axis: Axis, position: Double, speed: Int) async throws {
        try await runGCode("G1 \(axis.description)\(position) F\(getFParameter(speed))")
    }

    func moveAxisRelative(axis: Axis, distance: Double, speed: Int) async throws {
        // Relative positioning
        try await runGCode("G91")
        try await runGCode("G1 \(axis.description)\(distance) F\(getFParameter(speed))")
        // Reset to absolute positioning
        try await runGCode("G90")
    }

    func turnOffMotors() async throws {
        try await runGCode("M84")
    }

    // MARK: - Z-Offset Commands

    func adjustZOffset(_ offset: Double, positive: Bool, moveTool: Bool = true) async throws {
        let sign = positive ? "+" : "-"
        let moveValue = moveTool ? "1" : "0"
        try await runGCode("SET_GCODE_OFFSET Z_ADJUST=\(sign)\(offset) MOVE=\(moveValue)")
    }

    func saveZOffset() async throws {
        try await runGCode("Z_OFFSET_APPLY_ENDSTOP")
    }

    // MARK: - Extrusion Commands

    func extrude(_ distance: Int, speed: Int) async throws {
        // Set to relative extrusion
        try await runGCode("M83")
        try await runGCode("G1 E\(distance) F\(getFParameter(speed))")
    }

    // MARK: - Helper Methods

    /// Convert mm/s to mm/min for F parameter
    private func getFParameter(_ speed: Int) -> Int {
        return speed * 60
    }
}
