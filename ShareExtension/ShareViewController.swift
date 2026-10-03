import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Share sheet entry point: pulls a URL or text out of the extension context
/// and hands it to the capture API.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let host = UIHostingController(
            rootView: ShareView(
                load: { [weak self] in await self?.extractedPayload() ?? .init() },
                done: { [weak self] in self?.finish() }
            )
        )
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func extractedPayload() async -> CapturePayload {
        var payload = CapturePayload()
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return payload }

        for item in items {
            if let title = item.attributedContentText?.string, !title.isEmpty, payload.text.isEmpty {
                payload.text = title
            }
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                        payload.url = url.absoluteString
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                        payload.text = text
                    }
                }
            }
        }
        return payload
    }
}

struct CapturePayload {
    var url = ""
    var text = ""

    var isEmpty: Bool { url.isEmpty && text.isEmpty }
}
