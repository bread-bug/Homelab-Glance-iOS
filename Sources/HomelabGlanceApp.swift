import SwiftUI

@main
struct HomelabGlanceApp: App {
    var body: some Scene {
        WindowGroup {
            // CI screenshots a specific screen: `--sample --screen services`
            if SampleData.isEnabled, SampleData.screen == "services" {
                NavigationStack { ServicesView() }
            } else {
                GlanceView()
            }
        }
    }
}
