import SwiftUI

/// Polls while the view is on screen and the app is active, and refreshes
/// immediately on return from the background. Cancels when either stops being
/// true, so a backgrounded app costs nothing.
struct AutoRefresh: ViewModifier {
    let interval: Duration
    let action: () async -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .onAppear { visible = true }
            .onDisappear { visible = false }
            .task(id: TickKey(phase: scenePhase, visible: visible)) {
                guard visible, scenePhase == .active else { return }
                await action()
                while !Task.isCancelled {
                    try? await Task.sleep(for: interval)
                    if Task.isCancelled { return }
                    await action()
                }
            }
    }

    private struct TickKey: Equatable {
        let phase: ScenePhase
        let visible: Bool
    }
}

/// Runs a long-lived task only while on screen and active, cancelling it when
/// the app is backgrounded.
struct WhileVisible: ViewModifier {
    let action: () async -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .onAppear { visible = true }
            .onDisappear { visible = false }
            .task(id: Key(phase: scenePhase, visible: visible)) {
                guard visible, scenePhase == .active else { return }
                await action()
            }
    }

    private struct Key: Equatable {
        let phase: ScenePhase
        let visible: Bool
    }
}

extension View {
    func autoRefresh(every interval: Duration = .seconds(10), _ action: @escaping () async -> Void) -> some View {
        modifier(AutoRefresh(interval: interval, action: action))
    }

    func whileVisible(_ action: @escaping () async -> Void) -> some View {
        modifier(WhileVisible(action: action))
    }
}
