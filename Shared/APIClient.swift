import Foundation

enum APIError: LocalizedError {
    case notConfigured
    case unauthorized
    case server(Int)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "No server configured"
        case .unauthorized: "API key rejected"
        case .server(let code): "Server returned \(code)"
        case .transport(let message): message
        }
    }
}

struct APIClient {
    var baseURL: String
    var apiKey: String

    func services() async throws -> ServiceList {
        try await get("/api/v1/services")
    }

    func restart(service name: String) async throws {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        _ = try await send(path: "/api/v1/services/\(encoded)/restart", method: "POST")
    }

    func actions() async throws -> ActionList {
        try await get("/api/v1/actions")
    }

    func run(action id: String) async throws -> Job {
        let data = try await send(path: "/api/v1/actions/\(id)", method: "POST")
        return try Self.decoder.decode(Job.self, from: data)
    }

    func job(id: String) async throws -> Job {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return try await get("/api/v1/jobs/\(encoded)")
    }

    func captureTargets() async throws -> CaptureTargetList {
        try await get("/api/v1/capture/targets")
    }

    func capture(to target: String, url: String, text: String) async throws -> CaptureResult {
        var body: [String: String] = [:]
        if !url.isEmpty { body["url"] = url }
        if !text.isEmpty { body["text"] = text }
        let data = try await send(path: "/api/v1/capture/\(target)", method: "POST",
                                  body: try JSONEncoder().encode(body))
        return try Self.decoder.decode(CaptureResult.self, from: data)
    }

    func status() async throws -> Status {
        try await get("/api/v1/status")
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await send(path: path, method: "GET")
        return try Self.decoder.decode(T.self, from: data)
    }

    @discardableResult
    private func send(path: String, method: String, body: Data? = nil) async throws -> Data {
        guard !baseURL.isEmpty, !apiKey.isEmpty,
              let url = URL(string: baseURL.trimmedTrailingSlash + path) else {
            throw APIError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 30
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            // Preserve cancellation: wrapping it in APIError would erase the type
            // and make a restarted task look like a server failure.
            if isCancellation(error) { throw CancellationError() }
            throw APIError.transport(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw http.statusCode == 401 ? APIError.unauthorized : APIError.server(http.statusCode)
        }
        return data
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = Date.iso8601WithFraction.date(from: text) ?? Date.iso8601Plain.date(from: text) {
                return date
            }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                    debugDescription: "bad date: \(text)"))
        }
        return decoder
    }()
}

extension String {
    var trimmedTrailingSlash: String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}

extension Date {
    // Go emits RFC3339 with a variable number of fractional digits.
    static let iso8601WithFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let iso8601Plain = ISO8601DateFormatter()
}
