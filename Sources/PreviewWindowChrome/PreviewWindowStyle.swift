#if os(macOS)
import AppKit
import SwiftUI

/// Window style presets based on macOS Tahoe design specifications.
public enum PreviewWindowStyle: Sendable, Hashable {
    /// TitleBar-style window with 16pt corner radius.
    case titleBar
    /// Hidden title bar window with 16pt corner radius. Content extends behind the transparent title bar.
    case hiddenTitleBar
    /// Toolbar-style window (like Safari) with 26pt corner radius.
    case toolBar
    /// Custom corner radius.
    case custom(CGFloat)

    var cornerRadius: CGFloat {
        switch self {
        case .titleBar, .hiddenTitleBar: 16
        case .toolBar: 26
        case .custom(let radius): radius
        }
    }

    /// Safe area insets matching the window chrome for this style, measured from the system.
    @MainActor var safeAreaInsets: EdgeInsets {
        switch self {
        case .titleBar, .custom: Self.titleBarInsets
        case .hiddenTitleBar: Self.hiddenTitleBarInsets
        case .toolBar: Self.toolBarInsets
        }
    }

    @MainActor private static let titleBarInsets: EdgeInsets = {
        let frame = NSRect(x: 0, y: 0, width: 480, height: 300)
        let contentRect = NSWindow.contentRect(forFrameRect: frame,
                                               styleMask: [.titled, .closable, .miniaturizable, .resizable])
        return EdgeInsets(top: frame.height - contentRect.height, leading: 0, bottom: 0, trailing: 0)
    }()

    @MainActor private static let hiddenTitleBarInsets: EdgeInsets = {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered,
                              defer: true)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        let topInset = window.frame.height - window.contentLayoutRect.height
        return EdgeInsets(top: topInset, leading: 0, bottom: 0, trailing: 0)
    }()

    @MainActor private static let toolBarInsets: EdgeInsets = {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                              backing: .buffered,
                              defer: true)
        let toolbar = NSToolbar(identifier: "PreviewWindow.measure")
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        let topInset = window.frame.height - window.contentLayoutRect.height
        return EdgeInsets(top: topInset, leading: 0, bottom: 0, trailing: 0)
    }()
}

#endif // os(macOS)
