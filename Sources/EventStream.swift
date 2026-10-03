import Foundation

/// Reads the server's SSE stream and yields each decoded snapshot.
struct EventStream {
    let client: APIClient

    func statuses() -> AsyncThrowingStream<Status, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    guard !client.baseURL.isEmpty, !client.apiKey.isEmpty,
                          let url = URL(string: client.baseURL.trimmedTrailingSlash + "/api/v1/events") else {
                        throw APIError.notConfigured
                    }
                    var request = URLRequest(url: url)
                    request.setValue(client.apiKey, forHTTPHeaderField: "X-API-Key")
                    request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                    // the stream is long-lived; the default would kill it
                    request.timeoutInterval = .infinity

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                        throw http.statusCode == 401 ? APIError.unauthorized : APIError.server(http.statusCode)
                    }

                    for try await line in bytes.lines {
                        guard let payload = line.dropPrefixIfPresent("data: ") else { continue }
                        if let data = payload.data(using: .utf8),
                           let status = try? APIClient.decoder.decode(Status.self, from: data) {
                            continuation.yield(status)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: isCancellation(error) ? CancellationError() : error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private extension String {
    func dropPrefixIfPresent(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}
