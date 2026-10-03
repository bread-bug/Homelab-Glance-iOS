import Foundation
import Observation

@Observable
final class StatusStore {
    enum State {
        case idle
        case loading
        case loaded(Status)
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var lastUpdated: Date?
    private(set) var live = false

    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    /// Streams updates for as long as the caller's task lives, falling back to
    /// polling whenever the stream is unavailable.
    @MainActor
    func run() async {
        if SampleData.isEnabled {
            await load()
            return
        }
        while !Task.isCancelled {
            do {
                for try await status in EventStream(client: settings.client).statuses() {
                    state = .loaded(status)
                    lastUpdated = Date()
                    live = true
                }
                live = false
            } catch {
                live = false
                if case .loaded = state {} else {
                    state = .failed(error.localizedDescription)
                }
            }
            if Task.isCancelled { return }
            // stream dropped: poll once, then retry the stream shortly
            await load()
            try? await Task.sleep(for: .seconds(5))
        }
    }

    @MainActor
    func load() async {
        if SampleData.isEnabled, let status = Self.decodeSample() {
            state = .loaded(status)
            lastUpdated = Date()
            return
        }
        guard settings.isConfigured else {
            state = .failed(APIError.notConfigured.localizedDescription)
            return
        }
        if case .loaded = state {} else { state = .loading }

        do {
            let status = try await settings.client.status()
            state = .loaded(status)
            lastUpdated = Date()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private static func decodeSample() -> Status? {
        guard let data = SampleData.json.data(using: .utf8) else { return nil }
        return try? APIClient.decoder.decode(Status.self, from: data)
    }
}
