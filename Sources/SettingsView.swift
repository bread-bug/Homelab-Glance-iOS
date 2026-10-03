import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var testResult: String?
    @State private var testing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://glance.example.com", text: $settings.baseURL)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("API key", text: $settings.apiKey)
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Scheme and host only, with no trailing slash.")
                }

                Section {
                    Button(testing ? "Testing…" : "Test connection") {
                        Task { await test() }
                    }
                    .disabled(testing || !settings.isConfigured)

                    if let testResult {
                        Text(testResult).font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func test() async {
        testing = true
        defer { testing = false }
        do {
            let status = try await settings.client.status()
            testResult = "Connected — \(status.services.running) of \(status.services.total) services running"
        } catch {
            testResult = error.localizedDescription
        }
    }
}
