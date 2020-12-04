import Foundation

extension Bundle {
    @objc public class var rteBundle: Bundle {
        let defaultBundle = Bundle(for: EditorView.self)
        if let bundleURL = defaultBundle.resourceURL,
            let resourceBundle = Bundle(url: bundleURL.appendingPathComponent("RichTextEditor-iOS.bundle")) {
            return resourceBundle
        }
        // Otherwise, the default bundle is used for resources
        return defaultBundle
    }
}
