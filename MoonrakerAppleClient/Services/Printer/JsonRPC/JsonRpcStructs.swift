import AnyCodable
import Foundation

struct Param {
    let key: String
    var value: Any

    init(key: String, values: Any) {
        self.key = key
        self.value = values
    }
}

struct JSONRPCRequest: Codable {
    private let jsonrpc: String
    let method: String
    var params: [String: AnyCodable]?
    let id: Int

    init(method: String, params: [Param]?, id: Int) {
        self.jsonrpc = "2.0"
        self.method = method
        self.id = id

        if let parameters = params {
            self.params = [:]
            for param in parameters {
                self.params?[param.key] = AnyCodable(param.value)
            }
        } else {
            self.params = nil
        }
    }
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String
    let result: AnyCodable
    let id: Int
}

struct JSONRPCError: Codable, Error {
    let jsonrpc: String
    let error: ErrorDetails
    let id: Int

    struct ErrorDetails: Codable, Error {
        let code: Int
        let message: String
    }
}

struct JSONRPCNotification: Codable {
    let jsonrpc: String
    let method: String
    let params: AnyCodable?

    init(jsonrpc: String, method: String, params: AnyCodable?) {
        self.jsonrpc = jsonrpc
        self.method = method
        self.params = params
    }
}
