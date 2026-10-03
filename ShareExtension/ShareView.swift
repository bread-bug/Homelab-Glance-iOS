import SwiftUI

struct ShareView: View {
    let load: () async -> CapturePayload
    let done: () -> Void

    @State private var payload = CapturePayload()
    @State private var targets: [CaptureTarget] = []
    @State private var status: String?
    @State private var sending: String?
    @State private var settings = AppSettings.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Sharing") {
                    if !payload.url.isEmpty {
                        Text(payload.url).font(.caption).lineLimit(3)
                    }
                    if !payload.text.isEmpty {
                        Text(payload.text).font(.caption).lineLimit(3)
                    }
                    if payload.isEmpty {
                        Text("Nothing to share").foregroundStyle(.secondary)
                    }
                }

                if !settings.isConfigured {
                    Section {
                        Text("Open Glance and set the server address first.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Save to") {
                        ForEach(targets) { target in
                            Button {
                                send(to: target)
                            } label: {
                                HStack {
                                    Text(target.label).foregroundStyle(.primary)
                                    Spacer()
                                    if sending == target.id {
                                        ProgressView()
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(payload.isEmpty || sending != nil)
                        }
                        if targets.isEmpty {
                            Text("No targets configured").foregroundStyle(.secondary)
                        }
                    }
                }

                if let status {
                    Section { Text(status).font(.caption) }
                }
            }
            .navigationTitle("Glance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { done() }
                }
            }
            .task {
                payload = await load()
                targets = (try? await settings.client.captureTargets().targets) ?? []
            }
        }
    }

    private func send(to target: CaptureTarget) {
        sending = target.id
        Task {
            defer { sending = nil }
            do {
                let result = try await settings.client.capture(
                    to: target.id,
                    url: payload.url,
                    text: payload.text
                )
                if result.ok {
                    status = "Saved to \(target.label)"
                    try? await Task.sleep(for: .milliseconds(600))
                    done()
                } else {
                    status = result.detail ?? "Failed"
                }
            } catch {
                status = error.localizedDescription
            }
        }
    }
}
