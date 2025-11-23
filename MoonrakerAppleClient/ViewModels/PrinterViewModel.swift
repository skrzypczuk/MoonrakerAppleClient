import Combine
import Foundation

@MainActor
final class PrinterViewModel: ObservableObject {
    @Published var printerState = PrinterState()
    @Published var errors: [PrinterError] = []
    @Published var isConnected = false

    private let service: PrinterService
    private let api: PrinterAPI
    private let commands: PrinterCommands
    private let stateUpdater = PrinterStateUpdater()
    private var cancellables = Set<AnyCancellable>()

    init(url: URL) {
        self.service = PrinterService(url: url)
        self.api = PrinterAPI(service: service)
        self.commands = PrinterCommands(service: service)

        // Bind service connection state
        service.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)

        // Setup typed status update callbacks
        setupStatusUpdateCallbacks()

        Task { [weak self] in
            await self?.setup()  // do initial fetch + subscribe
        }
    }

    private func setup() async {
        await connect()
        await fetchInfo()
        await subscribeToStatusUpdates()
    }

    private func connect() async {
        do {
            try await service.connect()
            print("Successfully connected to printer")
        } catch {
            errors.append(.init(domain: "WebSocket", message: "\(error)"))
            print("Error connecting to printer: \(error)")
        }
    }

    func fetchInfo() async {
        do {
            let info = try await api.fetchPrinterInfo()
            printerState = info
            print("Successfully fetched printer info")
        } catch {
            errors.append(.init(domain: "API", message: "\(error)"))
            print("Error fetching printer info: \(error)")
        }
    }

    func subscribeToStatusUpdates() async {
        await api.statusUpdateSubscribe(
            printerObjects: printerState.printerObjects
        )
    }

    func homeX() async {
        do {
            try await commands.homeAxis(.x)
        } catch {
            errors.append(.init(domain: "Command", message: "\(error)"))
        }
    }

    func runGCode(_ code: String) async {
        do {
            try await commands.runGCode(code)
        } catch {
            errors.append(.init(domain: "Command", message: "\(error)"))
        }
    }

    // MARK: - Status Update Callbacks

    private func setupStatusUpdateCallbacks() {
        api.onExtruderUpdate = { [weak self] name, temp, target, power, canExtrude in
            guard let self else { return }
            self.stateUpdater.updateExtruder(
                state: &self.printerState,
                name: name,
                temp: temp,
                target: target,
                power: power,
                canExtrude: canExtrude
            )
        }

        api.onHeaterBedUpdate = { [weak self] temp, target, power in
            guard let self else { return }
            self.stateUpdater.updateHeaterBed(
                state: &self.printerState,
                temp: temp,
                target: target,
                power: power
            )
        }

        api.onToolheadUpdate = { [weak self] position, homedAxes in
            guard let self else { return }
            self.stateUpdater.updateToolhead(
                state: &self.printerState,
                position: position,
                homedAxes: homedAxes
            )
        }

        api.onGcodeMoveUpdate = { [weak self] speedFactor, speed, extrudeFactor in
            guard let self else { return }
            self.stateUpdater.updateGcodeMove(
                state: &self.printerState,
                speedFactor: speedFactor,
                speed: speed,
                extrudeFactor: extrudeFactor
            )
        }

        api.onPrintStatsUpdate = { [weak self] filename, totalDuration, printDuration, state in
            guard let self else { return }
            self.stateUpdater.updatePrintStats(
                state: &self.printerState,
                filename: filename,
                totalDuration: totalDuration,
                printDuration: printDuration,
                stateString: state
            )
        }

        api.onFilamentFanUpdate = { [weak self] speed, rpm in
            guard let self else { return }
            self.stateUpdater.updateFilamentFan(
                state: &self.printerState,
                speed: speed,
                rpm: rpm
            )
        }

        api.onTemperatureSensorUpdate = { [weak self] name, temp in
            guard let self else { return }
            self.stateUpdater.updateTemperatureSensor(
                state: &self.printerState,
                name: name,
                temp: temp
            )
        }

        api.onTemperatureFanUpdate = { [weak self] name, speed, temp, target in
            guard let self else { return }
            self.stateUpdater.updateTemperatureFan(
                state: &self.printerState,
                name: name,
                speed: speed,
                temp: temp,
                target: target
            )
        }

        api.onHeaterFanUpdate = { [weak self] name, speed, rpm in
            guard let self else { return }
            self.stateUpdater.updateHeaterFan(
                state: &self.printerState,
                name: name,
                speed: speed,
                rpm: rpm
            )
        }
    }
}
