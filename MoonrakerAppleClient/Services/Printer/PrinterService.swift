import AnyCodable
import Combine
import Foundation
import Starscream

final class PrinterService: ObservableObject {

    // MARK: - WebSocket
    private let socket: WebSocket
    private let url: URL

    var onNotification: ((String, Any) -> Void)?

    // MARK: - Continuations
    private var responseContinuations: [Int: CheckedContinuation<AnyCodable, Error>] = [:]
    private var ackContinuations: [Int: CheckedContinuation<Void, Error>] = [:]
    private var connectContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Published State
    @Published var isConnected = false
    @Published var rawResponses: [String] = []

    // MARK: - Init
    init(url: URL) {
        self.url = url
        var req = URLRequest(url: url)
        req.timeoutInterval = 6

        socket = WebSocket(request: req)
        socket.delegate = self
    }

    // MARK: - Send Request and Wait For ACK
    func sendRequest(
        method: String,
        params: [Param]? = nil,
        id: Int = 0
    ) async throws {
        guard isConnected else {
            throw PrinterError(domain: "WebSocket", message: "Not connected.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let requestId = id == 0 ? generateID() : id
            ackContinuations[requestId] = continuation

            let req = JSONRPCRequest(method: method, params: params, id: requestId)

            do {
                let data = try JSONEncoder().encode(req)
                socket.write(data: data)
                print("📤 Sent: \(req)")
            } catch {
                ackContinuations.removeValue(forKey: requestId)
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Send Request and Wait For Response
    func getRequest(
        method: String,
        params: [Param]? = nil
    ) async throws -> AnyCodable {

        let id = generateID()

        return try await withCheckedThrowingContinuation { continuation in
            responseContinuations[id] = continuation

            Task { [weak self] in
                guard let self else {
                    continuation.resume(
                        throwing: PrinterError(domain: "Service", message: "Service deallocated"))
                    return
                }
                do {
                    try await self.sendRequest(method: method, params: params, id: id)
                } catch {
                    self.responseContinuations.removeValue(forKey: id)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - ID Generator
    private func generateID() -> Int {
        var id: Int
        repeat {
            id = Int.random(in: 1...9999)
        } while responseContinuations[id] != nil || ackContinuations[id] != nil
        return id
    }
}

// MARK: - WebSocketDelegate
extension PrinterService: WebSocketDelegate {

    func connect() async throws {
        guard !isConnected else { return }

        return try await withCheckedThrowingContinuation { continuation in
            self.connectContinuation = continuation
            socket.connect()
        }
    }

    func disconnect() {
        socket.disconnect()
    }

    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {

        case .connected:
            print("🔌 WebSocket Connected")
            Task { @MainActor in
                isConnected = true
            }
            connectContinuation?.resume()
            connectContinuation = nil

        case .disconnected(let reason, let code):
            print("🔌 Disconnected: \(reason) (\(code))")
            Task { @MainActor in
                isConnected = false
            }
            connectContinuation?.resume(
                throwing: PrinterError(domain: reason, message: "Code: \(code)"))
            connectContinuation = nil

        case .error(let err):
            print("❌ WS Error: \(String(describing: err))")
            connectContinuation?.resume(
                throwing: err ?? PrinterError(domain: "Unknown", message: "No error"))
            connectContinuation = nil

        case .text(let text):
            rawResponses.append(text)
            handleIncoming(text)

        default:
            break
        }
    }

    // MARK: - Incoming Message Handler
    private func handleIncoming(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        // Try parse as successful response
        if let rpc = try? JSONDecoder().decode(JSONRPCResponse.self, from: data) {
            print("📥 Received Response: \(rpc)")
            if let continuation = responseContinuations[rpc.id] {
                continuation.resume(returning: rpc.result)
                responseContinuations.removeValue(forKey: rpc.id)
            }
            if let ack = ackContinuations[rpc.id] {
                ack.resume()
                ackContinuations.removeValue(forKey: rpc.id)
            }
            return
        }

        // Parse as error
        if let rpcErr = try? JSONDecoder().decode(JSONRPCError.self, from: data) {
            print("❌ RPC Error: \(rpcErr.error.message)")

            if let ack = ackContinuations[rpcErr.id] {
                ack.resume(throwing: rpcErr.error)
                ackContinuations.removeValue(forKey: rpcErr.id)
            }
            if let cont = responseContinuations[rpcErr.id] {
                cont.resume(throwing: rpcErr.error)
                responseContinuations.removeValue(forKey: rpcErr.id)
            }
            return
        }

        // Parse as notification
        if let notification = try? JSONDecoder().decode(JSONRPCNotification.self, from: data) {
            handleNotification(notification)
            return
        }

        print("⚠️ Unknown WebSocket message: \(text)")
    }

    // MARK: - Notification Handler
    private func handleNotification(_ notification: JSONRPCNotification) {
        guard let method = notification.method as String? else { return }
        onNotification?(method, notification.params?.value as Any)
    }
}
