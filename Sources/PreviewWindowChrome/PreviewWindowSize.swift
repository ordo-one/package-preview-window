#if os(macOS)
import SwiftUI

/// Window size options for PreviewWindow.
public enum PreviewWindowSize: Sendable {
    /// Fixed window size with specific dimensions.
    case fixed(width: CGFloat, height: CGFloat)
    /// Window size to fit its content.
    case contentSize
}

#endif // os(macOS)
