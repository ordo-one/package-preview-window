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

/// A preview wrapper that simulates macOS window chrome for views with transparency.
///
/// Use this to preview views that rely on window styling like `.containerBackground(.thinMaterial, for: .window)`
/// or `.presentedWindowStyle(.hiddenTitleBar)` which don't render in standard SwiftUI previews.
///
/// When using the default wallpaper, interactive pickers for wallpaper style,
/// window style, background, and appearance are overlaid as a glass capsule.
///
/// Example:
/// ```swift
/// #Preview {
///     PreviewWindow {
///         MyTransparentView()
///     }
///     .previewWindowStyle(.toolBar)
///     .previewWindowTitle("My App")
///     .previewWindowBackground(.glass(.regular))
///     .previewWallpaper(.sunset, appearance: .dark)
/// }
/// ```
public struct PreviewWindow<Content: View, Wallpaper: View>: View {

    /// The background style applied to the simulated window content area.
    public enum BackgroundStyle {
        /// System default background.
        case defaultStyle
        /// A material blur background. Pass `nil` for a clear background.
        case material(Material?)
        /// A Liquid Glass background.
        case glass(Glass)
    }

    private enum BackgroundOption: Hashable {
        case defaultStyle, clear
        case ultraThinMaterial, thinMaterial, regularMaterial, thickMaterial, ultraThickMaterial, barMaterial
        case glassClear, glassRegular
    }

    private enum WindowStyleOption: Hashable {
        case titleBar, hiddenTitleBar, toolBar
    }

    let content: Content
    let wallpaper: Wallpaper
    var windowSize: PreviewWindowSize = .contentSize
    @State private var windowStyleOption: WindowStyleOption = .titleBar
    var showTrafficLights: Bool = true
    var windowTitle: String = "Preview Window"
    @State private var backgroundOption: BackgroundOption = .defaultStyle
    @State private var wallpaperStyle: PreviewWallpaper.Style = .ocean
    @State private var wallpaperAppearance: ColorScheme?

    private var windowStyle: PreviewWindowStyle {
        switch windowStyleOption {
        case .titleBar: .titleBar
        case .hiddenTitleBar: .hiddenTitleBar
        case .toolBar: .toolBar
        }
    }

    private var backgroundStyle: BackgroundStyle {
        switch backgroundOption {
        case .defaultStyle: .defaultStyle
        case .clear: .material(nil)
        case .ultraThinMaterial: .material(.ultraThinMaterial)
        case .thinMaterial: .material(.thinMaterial)
        case .regularMaterial: .material(.regularMaterial)
        case .thickMaterial: .material(.thickMaterial)
        case .ultraThickMaterial: .material(.ultraThickMaterial)
        case .barMaterial: .material(.bar)
        case .glassClear: .glass(.clear)
        case .glassRegular: .glass(.regular)
        }
    }

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

    /// Sets the initial window style.
    ///
    /// When using the default wallpaper, the window style can be changed
    /// interactively through the control bar overlay.
    public func previewWindowStyle(_ style: PreviewWindowStyle) -> Self {
        var copy = self
        let option: WindowStyleOption
        switch style {
        case .titleBar: option = .titleBar
        case .hiddenTitleBar: option = .hiddenTitleBar
        case .toolBar: option = .toolBar
        case .custom: option = .titleBar
        }
        copy._windowStyleOption = State(initialValue: option)
        return copy
    }

    /// Sets the initial window background style (material, glass, or default system background).
    ///
    /// When using the default wallpaper, the background style can be changed
    /// interactively through the control bar overlay.
    public func previewWindowBackground(_ style: BackgroundStyle) -> Self {
        var copy = self
        let option: BackgroundOption
        switch style {
        case .defaultStyle: option = .defaultStyle
        case .material(.none): option = .clear
        case .material(.some): option = .regularMaterial
        case .glass: option = .glassRegular
        }
        copy._backgroundOption = State(initialValue: option)
        return copy
    }

    /// Shows or hides the traffic light buttons.
    public func previewTrafficLights(_ visible: Bool) -> Self {
        var copy = self
        copy.showTrafficLights = visible
        return copy
    }

    /// Sets the window title displayed in the title bar.
    public func previewWindowTitle(_ title: String) -> Self {
        var copy = self
        copy.windowTitle = title
        return copy
    }

    /// Sets the default wallpaper style and optionally locks it to a specific appearance.
    public func previewWallpaper(_ style: PreviewWallpaper.Style, appearance: ColorScheme? = nil) -> Self {
        var copy = self
        copy._wallpaperStyle = State(initialValue: style)
        copy._wallpaperAppearance = State(initialValue: appearance)
        return copy
    }

    private let wallpaperPadding: CGFloat = 200

    public var body: some View {
        // Simulated window
        windowContent
            .containerShape(windowShape)
            .clipShape(windowShape)
        // Inner white border (highlight)
            .overlay {
                windowShape
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            }
        // Outer black border (definition)
            .overlay {
                windowShape
                    .strokeBorder(Color.black.opacity(0.2), lineWidth: 0.5)
                    .padding(-0.5)
            }
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(wallpaperPadding)
            .overlay(alignment: .bottom) {
                if Wallpaper.self == EmptyView.self {
                    wallpaperControls
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.bottom, 40)
                }
            }
            .background {
                if Wallpaper.self == EmptyView.self {
                    defaultWallpaper
                } else {
                    wallpaper
                }
            }
            .clipped()
    }

    private var wallpaperControls: some View {
        HStack(alignment: .center, spacing: 16) {
            Picker("Wallpaper", systemImage: "photo.fill", selection: $wallpaperStyle) {
                Text("Ocean").tag(PreviewWallpaper.Style.ocean)
                Text("Sunset").tag(PreviewWallpaper.Style.sunset)
                Text("Meadow").tag(PreviewWallpaper.Style.meadow)
                Text("Solid").tag(PreviewWallpaper.Style.solid)
                Text("Contrast").tag(PreviewWallpaper.Style.highContrast)
            }

            Picker("Background", systemImage: "rectangle.on.rectangle", selection: $backgroundOption) {
                Text("Default").tag(BackgroundOption.defaultStyle)
                Text("Clear").tag(BackgroundOption.clear)
                Divider()
                Text("Ultra Thin").tag(BackgroundOption.ultraThinMaterial)
                Text("Thin").tag(BackgroundOption.thinMaterial)
                Text("Regular").tag(BackgroundOption.regularMaterial)
                Text("Thick").tag(BackgroundOption.thickMaterial)
                Text("Ultra Thick").tag(BackgroundOption.ultraThickMaterial)
                Text("Bar").tag(BackgroundOption.barMaterial)
                Divider()
                Text("Glass Clear").tag(BackgroundOption.glassClear)
                Text("Glass Regular").tag(BackgroundOption.glassRegular)
            }

            Picker("Window Style", systemImage: "macwindow", selection: $windowStyleOption) {
                Text("Title Bar").tag(WindowStyleOption.titleBar)
                Text("Hidden Title Bar").tag(WindowStyleOption.hiddenTitleBar)
                Text("Toolbar").tag(WindowStyleOption.toolBar)
            }

            Picker("Appearance", systemImage: "circle.lefthalf.filled", selection: $wallpaperAppearance) {
                Text("Auto").tag(ColorScheme?.none)
                Text("Light").tag(ColorScheme?.some(.light))
                Text("Dark").tag(ColorScheme?.some(.dark))
            }
        }
        .tint(.clear)
        .controlSize(.mini)
        .pickerStyle(.menu)
        .font(.caption)
        .foregroundStyle(.secondary)
        .labelStyle(.iconOnly)
    }

    private var windowContent: some View {
        ZStack(alignment: .top) {
            framedContent
                .safeAreaPadding(windowStyle.safeAreaInsets)
                .windowBackground(style: backgroundStyle)
                .layoutPriority(2)

            if showsTitleBar {
                titleBar
                    .layoutPriority(1)

            } else if showTrafficLights {
                TrafficLights()
                    .padding(.leading, 13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: windowStyle.safeAreaInsets.top)
            }
        }
        .windowFrame(windowSize)
    }

    private var showsTitleBar: Bool { windowStyleOption != .hiddenTitleBar }

    private var titleBar: some View {
        HStack(spacing: 8) {
            if showTrafficLights {
                TrafficLights()
            }
            Text(windowTitle)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 13)
        .frame(height: windowStyle.safeAreaInsets.top)
        .background(.bar, in: ConcentricRectangle(corners: .concentric))
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

    @ViewBuilder
    private var defaultWallpaper: some View {
        let wallpaper = PreviewWallpaper(wallpaperStyle)
        if let wallpaperAppearance {
            wallpaper.appearance(wallpaperAppearance)
        } else {
            wallpaper
        }
    }
}

private extension View {
    @ViewBuilder
    func windowFrame(_ size: PreviewWindowSize) -> some View {
        switch size {
        case .fixed(let width, let height): self.frame(width: width, height: height)
        case .contentSize: self
        }
    }


    @ViewBuilder
    func windowBackground<Content: View, Wallpaper: View>(style: PreviewWindow<Content, Wallpaper>.BackgroundStyle) -> some View {
        switch style {
        case .defaultStyle:
            self.background()
        case .material(let material):
            if let material {
                self.background(material)
            } else {
                self.background(.clear)
            }
        case .glass(let glass):
            self.glassEffect(glass, in: .containerRelative)
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
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.glass(.clear))
                Button("Delete", role: .destructive) {}
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.glassProminent)
                    .tint(.red)
            }
        }
        .padding(20)
    }
    .previewWindowStyle(.hiddenTitleBar)
    .previewWindowBackground(.material(.regular))
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
    .previewWindowBackground(.glass(.regular))
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
            ForEach(1 ... 10, id: \.self) { i in
                Text("Item \(i)")
            }
        }
        .scrollContentBackground(.hidden)
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
}

// MARK: Safe Area Diagnostics

private struct SafeAreaDiagnostic: View {
    let label: String
    let insets: EdgeInsets

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Color.red.opacity(0.25)
                    .frame(height: insets.top)
                    .frame(maxWidth: .infinity)

                Color.green.opacity(0.1)
                    .padding(.top, insets.top)

                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
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
}

#Preview("Safe Area Diagnostic - TitleBar") {
    PreviewWindow { SafeAreaDiagnostic(label: "titleBar", insets: PreviewWindowStyle.titleBar.safeAreaInsets) }
        .previewWindowSize(.fixed(width: 500, height: 300))
}

#Preview("Safe Area Diagnostic - HiddenTitleBar") {
    PreviewWindow { SafeAreaDiagnostic(label: "hiddenTitleBar", insets: PreviewWindowStyle.hiddenTitleBar.safeAreaInsets) }
        .previewWindowSize(.fixed(width: 500, height: 300))
        .previewWindowStyle(.hiddenTitleBar)
}

#Preview("Safe Area Diagnostic - ToolBar") {
    PreviewWindow { SafeAreaDiagnostic(label: "toolBar", insets: PreviewWindowStyle.toolBar.safeAreaInsets) }
        .previewWindowSize(.fixed(width: 500, height: 300))
        .previewWindowStyle(.toolBar)
}

#endif
