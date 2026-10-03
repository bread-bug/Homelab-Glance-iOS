import Observation
import Foundation

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

    private let settings: AppSettings

    init(settings: AppSettings = .shared) {
        self.settings = settings
    }

    private static func decodeSample() -> Status? {
        guard let data = SampleData.json.data(using: .utf8) else { return nil }
        return try? APIClient.decoder.decode(Status.self, from: data)
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
}
