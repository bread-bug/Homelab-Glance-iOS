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

    func status() async throws -> Status {
        guard let url = URL(string: baseURL.trimmedTrailingSlash + "/api/v1/status"),
              !baseURL.isEmpty, !apiKey.isEmpty else {
            throw APIError.notConfigured
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.timeoutInterval = 15

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw http.statusCode == 401 ? APIError.unauthorized : APIError.server(http.statusCode)
        }

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
        return try decoder.decode(Status.self, from: data)
    }
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
