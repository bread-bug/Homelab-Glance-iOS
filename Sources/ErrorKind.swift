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
