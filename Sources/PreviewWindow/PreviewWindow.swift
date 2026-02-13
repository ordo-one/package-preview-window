import AppKit
import SwiftUI

/// Window size options for PreviewWindow.
public enum PreviewWindowSize {
    /// Fixed window size with specific dimensions.
    case fixed(width: CGFloat, height: CGFloat)
    /// Window size to fit its content.
    case contentSize
}

/// Window style presets based on macOS Tahoe design specifications.
public enum PreviewWindowStyle {
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
        let contentRect = NSWindow.contentRect(
            forFrameRect: frame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable]
        )
        return EdgeInsets(top: frame.height - contentRect.height, leading: 0, bottom: 0, trailing: 0)
    }()

    @MainActor private static let hiddenTitleBarInsets: EdgeInsets = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        let topInset = window.frame.height - window.contentLayoutRect.height
        return EdgeInsets(top: topInset, leading: 0, bottom: 0, trailing: 0)
    }()

    @MainActor private static let toolBarInsets: EdgeInsets = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        let toolbar = NSToolbar(identifier: "PreviewWindow.measure")
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        let topInset = window.frame.height - window.contentLayoutRect.height
        return EdgeInsets(top: topInset, leading: 0, bottom: 0, trailing: 0)
    }()
}

/// A preview wrapper that simulates macOS window chrome for views with transparency.
///
/// Use this to preview views that rely on window styling like `.containerBackground(.thinMaterial, for: .window)`
/// or `.presentedWindowStyle(.hiddenTitleBar)` which don't render in standard SwiftUI previews.
///
/// Example:
/// ```swift
/// #Preview {
///     PreviewWindow {
///         MyTransparentView()
///     }
///     .previewWindowStyle(.toolBar)
///     .previewBackgroundGlass(.regular)
/// }
/// ```
public struct PreviewWindow<Content: View, Wallpaper: View>: View {
    let content: Content
    let wallpaper: Wallpaper
    var windowSize: PreviewWindowSize = .contentSize
    var windowStyle: PreviewWindowStyle = .titleBar
    var windowMaterial: Material? = .thinMaterial
    var showTrafficLights: Bool = true
    var backgroundGlass: Glass?

    /// Creates a preview window chrome wrapper.
    public init(@ViewBuilder content: () -> Content) where Wallpaper == EmptyView {
        self.wallpaper = EmptyView()
        self.content = content()
    }

    /// Creates a preview window chrome wrapper with a custom wallpaper.
    public init(@ViewBuilder wallpaper: () -> Wallpaper,
                @ViewBuilder content: () -> Content) {
        self.wallpaper = wallpaper()
        self.content = content()
    }

    // MARK: Modifiers

    /// Sets the window size.
    public func previewWindowSize(_ size: PreviewWindowSize) -> Self {
        var copy = self
        copy.windowSize = size
        return copy
    }

    /// Sets the window style.
    public func previewWindowStyle(_ style: PreviewWindowStyle) -> Self {
        var copy = self
        copy.windowStyle = style
        return copy
    }

    /// Sets the window background material. Pass `nil` for no background.
    public func previewWindowMaterial(_ material: Material?) -> Self {
        var copy = self
        copy.windowMaterial = material
        copy.backgroundGlass = nil
        return copy
    }

    /// Sets a Liquid Glass background. Replaces any material background.
    public func previewBackgroundGlass(_ glass: Glass) -> Self {
        var copy = self
        copy.backgroundGlass = glass
        copy.windowMaterial = nil
        return copy
    }

    /// Shows or hides the traffic light buttons.
    public func previewTrafficLights(_ visible: Bool) -> Self {
        var copy = self
        copy.showTrafficLights = visible
        return copy
    }

    private let wallpaperPadding: CGFloat = 50

    public var body: some View {
        // Simulated window
        windowContent
            .containerShape(windowShape)
            .clipShape(windowShape)
        // Inner white border (highlight)
            .overlay {
                windowShape
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
            }
        // Outer black border (definition)
            .overlay {
                windowShape
                    .strokeBorder(Color.black.opacity(0.2), lineWidth: 0.5)
                    .padding(-0.5)
            }
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(wallpaperPadding)
            .background {
                if Wallpaper.self == EmptyView.self {
                    defaultWallpaper
                } else {
                    wallpaper
                }
            }
            .clipped()

    }

    @ViewBuilder
    private var windowContent: some View {
        ZStack(alignment: .topLeading) {
            framedContent
                .safeAreaPadding(windowStyle.safeAreaInsets)
                .windowBackground(material: windowMaterial, glass: backgroundGlass)

            if showTrafficLights {
                TrafficLights()
                    .padding(.leading, 13)
                    .padding(.top, 13)
            }
        }
        .modifier(WindowFrameModifier(windowSize: windowSize))
    }

    @ViewBuilder
    private var framedContent: some View {
        switch windowSize {
        case .fixed:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .contentSize:
            content
        }
    }

    private var windowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: windowStyle.cornerRadius, style: .continuous)
    }

    private var defaultWallpaper: some View {
        Image("PreviewWallpaper", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}

private struct WindowFrameModifier: ViewModifier {
    let windowSize: PreviewWindowSize

    func body(content: Content) -> some View {
        switch windowSize {
        case .fixed(let width, let height):
            content.frame(width: width, height: height)
        case .contentSize:
            content
        }
    }
}

private extension View {
    @ViewBuilder
    func windowBackground(material: Material?, glass: Glass?) -> some View {
        if let material {
            self.background(material)
        } else if let glass {
            self.glassEffect(glass, in: .containerRelative)
        } else {
            self
        }
    }
}

private struct TrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(red: 1.0, green: 0.38, blue: 0.35))
                .frame(width: 12, height: 12)
            Circle()
                .fill(Color(red: 1.0, green: 0.78, blue: 0.25))
                .frame(width: 12, height: 12)
            Circle()
                .fill(Color(red: 0.15, green: 0.8, blue: 0.25))
                .frame(width: 12, height: 12)
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("TitleBar Style (16pt) - Clear Background") {
    PreviewWindow {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text("Are you sure?")
                .font(.headline)

            Text("This action cannot be undone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Cancel") {}
                    .buttonStyle(.glass)
                Button("Delete") {}
                    .buttonStyle(.glassProminent)
                    .tint(.red)
            }
        }
        .padding(20)
    }
    .previewWindowMaterial(nil)
}

#Preview("TitleBar Style - Glass") {
    PreviewWindow {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notifications", systemImage: "bell.fill")
                .font(.headline)

            Toggle("Enable alerts", isOn: .constant(true))
            Toggle("Play sound", isOn: .constant(false))
            Toggle("Show badge", isOn: .constant(true))
        }
        .padding(16)
        .frame(width: 280)
    }
    .previewBackgroundGlass(.regular)
}

#Preview("Toolbar Style (26pt)") {
    PreviewWindow {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("Connection Successful")
                .font(.title2)
                .fontWeight(.semibold)

            Text("You are now connected to the server.")
                .foregroundStyle(.secondary)

            Button("Continue") {}
                .buttonStyle(.glassProminent)
        }
        .padding(20)
    }
    .previewWindowStyle(.toolBar)
}

#Preview("Fixed Size") {
    PreviewWindow {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Settings")
                .font(.title2)
                .fontWeight(.semibold)

            Divider()

            ForEach(["Dark Mode", "Auto-Save", "Sync to Cloud"], id: \.self) { item in
                HStack {
                    Text(item)
                    Spacer()
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") {}
                    .buttonStyle(.glassProminent)
            }
        }
        .padding(24)
    }
    .previewWindowSize(.fixed(width: 500, height: 350))
}

#Preview("Content Size") {
    PreviewWindow {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading...")
                .font(.headline)

            Text("Please wait while we fetch your data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }
}

#Preview("Content with safeAreaInset bar") {
    PreviewWindow {
        List {
            ForEach(1...10, id: \.self) { i in
                Text("Item \(i)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(.thickMaterial)
        .safeAreaInset(edge: .top) {
            HStack {
                Text("All Mail")
                    .font(.headline)
                Spacer()
                Button("Filter", systemImage: "line.3.horizontal.decrease") {}
                    .buttonStyle(.glass)
            }
            .padding(12)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Text("3 items selected")
                Spacer()
                Button("Delete") {}
                    .buttonStyle(.glassProminent)
                    .tint(.red)
            }
            .padding(12)
            .glassEffect(.regular.tint(.primary.opacity(0.1)), in: ConcentricRectangle(corners: .concentric))
        }
    }
    .previewWindowSize(.fixed(width: 500, height: 350))
    .previewWindowStyle(.hiddenTitleBar)
    .previewWindowMaterial(.ultraThin)
}

// MARK: Safe Area Diagnostics

#Preview("Safe Area Diagnostic - TitleBar") {
    let insets = PreviewWindowStyle.titleBar.safeAreaInsets
    PreviewWindow {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.red.opacity(0.25)
                    .frame(height: insets.top)
                    .frame(maxWidth: .infinity)

                Color.green.opacity(0.1)
                    .padding(.top, insets.top)

                VStack(alignment: .leading, spacing: 4) {
                    Text("titleBar")
                    Text("Probed: \(insets.top, specifier: "%.1f")pt")
                    Text("Geometry: \(geometry.safeAreaInsets.top, specifier: "%.1f")pt")
                }
                .font(.system(.caption, design: .monospaced))
                .padding(.top, insets.top + 8)
                .padding(.leading, 12)
            }
        }
        .ignoresSafeArea()
    }
    .previewWindowSize(.fixed(width: 500, height: 300))
}

#Preview("Safe Area Diagnostic - HiddenTitleBar") {
    let insets = PreviewWindowStyle.hiddenTitleBar.safeAreaInsets
    PreviewWindow {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.red.opacity(0.25)
                    .frame(height: insets.top)
                    .frame(maxWidth: .infinity)

                Color.green.opacity(0.1)
                    .padding(.top, insets.top)

                VStack(alignment: .leading, spacing: 4) {
                    Text("hiddenTitleBar")
                    Text("Probed: \(insets.top, specifier: "%.1f")pt")
                    Text("Geometry: \(geometry.safeAreaInsets.top, specifier: "%.1f")pt")
                }
                .font(.system(.caption, design: .monospaced))
                .padding(.top, insets.top + 8)
                .padding(.leading, 12)
            }
        }
        .ignoresSafeArea()
    }
    .previewWindowSize(.fixed(width: 500, height: 300))
    .previewWindowStyle(.hiddenTitleBar)
}

#Preview("Safe Area Diagnostic - ToolBar") {
    let insets = PreviewWindowStyle.toolBar.safeAreaInsets
    PreviewWindow {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.red.opacity(0.25)
                    .frame(height: insets.top)
                    .frame(maxWidth: .infinity)

                Color.green.opacity(0.1)
                    .padding(.top, insets.top)

                VStack(alignment: .leading, spacing: 4) {
                    Text("toolBar")
                    Text("Probed: \(insets.top, specifier: "%.1f")pt")
                    Text("Geometry: \(geometry.safeAreaInsets.top, specifier: "%.1f")pt")
                }
                .font(.system(.caption, design: .monospaced))
                .padding(.top, insets.top + 8)
                .padding(.leading, 12)
            }
        }
        .ignoresSafeArea()
    }
    .previewWindowSize(.fixed(width: 500, height: 300))
    .previewWindowStyle(.toolBar)
}

#endif
