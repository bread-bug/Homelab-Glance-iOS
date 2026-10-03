import Foundation

/// A cancelled request means the view's task restarted, not that the server
/// failed; surfacing it as an error flashes a failure screen on launch.
func isCancellation(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    if let urlError = error as? URLError, urlError.code == .cancelled { return true }
    if (error as NSError).domain == NSURLErrorDomain,
       (error as NSError).code == NSURLErrorCancelled { return true }
    return false
}

/// Full detail for on-screen diagnosis: the message alone hides which layer
/// actually threw.
func errorDetail(_ error: Error) -> String {
    let ns = error as NSError
    return """
    \(type(of: error))
    domain: \(ns.domain)
    code: \(ns.code)
    \(error.localizedDescription)
    """
}

enum AppVersion {
    static var display: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}
