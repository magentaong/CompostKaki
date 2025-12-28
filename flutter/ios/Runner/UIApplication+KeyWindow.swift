import UIKit

// Extension to provide a modern replacement for deprecated keyWindow
// This fixes the deprecation warning for iOS 13.0+
extension UIApplication {
    /// Returns the key window for the app, compatible with iOS 13.0+
    /// This replaces the deprecated `keyWindow` property
    var keyWindowCompat: UIWindow? {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return keyWindow
        }
    }
    
    /// Returns all windows in the app, compatible with iOS 13.0+
    var windowsCompat: [UIWindow] {
        if #available(iOS 13.0, *) {
            return connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
        } else {
            return windows
        }
    }
}























