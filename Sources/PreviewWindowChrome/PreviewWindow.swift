#if os(macOS)
import AppKit
import SwiftUI

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
///     .previewWindowPadding(100)
/// }
/// ```
public struct PreviewWindow<Content: View, Wallpaper: View>: View {
    private enum WallpaperOption: Hashable, CaseIterable {
        case oceanDark, oceanLight
        case sunsetDark, sunsetLight
        case meadowDark, meadowLight
        case solidDark, solidLight
        case highContrast
    }

    private let content: Content
    private let wallpaper: Wallpaper
    private var windowSize: PreviewWindowSize = .contentSize
    @State private var windowStyle: PreviewWindowStyle = .titleBar
    private var showTrafficLights: Bool = true
    private var showWallpaperControls: Bool = true
    private var windowTitle: String = "Preview Window"
    @State private var backgroundOption: PreviewWindowBackground = .defaultStyle
    @State private var wallpaperOption: WallpaperOption = .oceanDark
    @State private var colorSchemeOverride: ColorScheme?
    @Environment(\.colorScheme) private var environmentColorScheme
    @State private var windowPosition: CGSize = .zero
    @State private var dragStartPosition: CGSize?

    private var backgroundStyle: PreviewWindowBackground {
        backgroundOption
    }

    private var wallpaperStyle: PreviewWallpaper.Style {
        switch wallpaperOption {
        case .oceanDark, .oceanLight: .ocean
        case .sunsetDark, .sunsetLight: .sunset
        case .meadowDark, .meadowLight: .meadow
        case .solidDark, .solidLight: .solid
        case .highContrast: .highContrast
        }
    }

    private var wallpaperAppearance: ColorScheme? {
        switch wallpaperOption {
        case .oceanDark, .sunsetDark, .meadowDark, .solidDark: .dark
        case .oceanLight, .sunsetLight, .meadowLight, .solidLight: .light
        case .highContrast: nil
        }
    }

    private func stepWallpaper(by offset: Int) {
        let cases = WallpaperOption.allCases
        guard let currentIndex = cases.firstIndex(of: wallpaperOption) else { return }
        let newIndex = (currentIndex + offset + cases.count) % cases.count
        wallpaperOption = cases[newIndex]
    }

    private static func wallpaperOption(for style: PreviewWallpaper.Style, appearance: ColorScheme) -> WallpaperOption {
        switch (style, appearance) {
        case (.ocean, .light): .oceanLight
        case (.ocean, _): .oceanDark
        case (.sunset, .light): .sunsetLight
        case (.sunset, _): .sunsetDark
        case (.meadow, .light): .meadowLight
        case (.meadow, _): .meadowDark
        case (.solid, .light): .solidLight
        case (.solid, _): .solidDark
        case (.highContrast, _): .highContrast
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
        copy._windowStyle = State(initialValue: style)
        return copy
    }

    /// Sets the initial window background style (material, glass, or default system background).
    ///
    /// When using the default wallpaper, the background style can be changed
    /// interactively through the control bar overlay.
    public func previewWindowBackground(_ style: PreviewWindowBackground) -> Self {
        var copy = self
        copy._backgroundOption = State(initialValue: style)
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

    /// Sets the padding between the wallpaper edge and the simulated window.
    public func previewWindowPadding(_ padding: CGFloat) -> Self {
        var copy = self
        copy.wallpaperPadding = padding
        return copy
    }

    /// Shows or hides the interactive wallpaper control bar overlay.
    public func previewWallpaperControls(_ visible: Bool) -> Self {
        var copy = self
        copy.showWallpaperControls = visible
        return copy
    }

    /// Sets the default wallpaper style and appearance variant.
    public func previewWallpaper(_ style: PreviewWallpaper.Style, appearance: ColorScheme = .dark) -> Self {
        var copy = self
        copy._wallpaperOption = State(initialValue: Self.wallpaperOption(for: style, appearance: appearance))
        return copy
    }

    /// Overrides the color scheme for the simulated window content.
    public func previewColorScheme(_ scheme: ColorScheme?) -> Self {
        var copy = self
        copy._colorSchemeOverride = State(initialValue: scheme)
        return copy
    }

    private var wallpaperPadding: CGFloat = 200

    public var body: some View {
        // Simulated window
        windowContent
            .environment(\.colorScheme, colorSchemeOverride ?? environmentColorScheme)
            .fixedSize()
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
            .offset(x: windowPosition.width, y: windowPosition.height)
            .padding(wallpaperPadding)
            .overlay(alignment: .bottom) {
                if showWallpaperControls, Wallpaper.self == EmptyView.self {
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
            HStack(spacing: 8) {
                Picker("Wallpaper", systemImage: "photo.fill", selection: $wallpaperOption) {
                    Text("Ocean-Dark").tag(WallpaperOption.oceanDark)
                    Text("Ocean-Light").tag(WallpaperOption.oceanLight)
                    Divider()
                    Text("Sunset-Dark").tag(WallpaperOption.sunsetDark)
                    Text("Sunset-Light").tag(WallpaperOption.sunsetLight)
                    Divider()
                    Text("Meadow-Dark").tag(WallpaperOption.meadowDark)
                    Text("Meadow-Light").tag(WallpaperOption.meadowLight)
                    Divider()
                    Text("Solid-Dark").tag(WallpaperOption.solidDark)
                    Text("Solid-Light").tag(WallpaperOption.solidLight)
                    Divider()
                    Text("Contrast").tag(WallpaperOption.highContrast)
                }

                Stepper("Wallpaper") {
                    stepWallpaper(by: 1)
                } onDecrement: {
                    stepWallpaper(by: -1)
                }
                .labelsHidden()
                .controlSize(.small)
                .rotationEffect(.degrees(90))
            }

            Picker("Background", systemImage: "rectangle.on.rectangle", selection: $backgroundOption) {
                Text("Default").tag(PreviewWindowBackground.defaultStyle)
                Text("Clear").tag(PreviewWindowBackground.clear)
                Divider()
                Text("Ultra Thin").tag(PreviewWindowBackground.material(.ultraThin))
                Text("Thin").tag(PreviewWindowBackground.material(.thin))
                Text("Regular").tag(PreviewWindowBackground.material(.regular))
                Text("Thick").tag(PreviewWindowBackground.material(.thick))
                Text("Ultra Thick").tag(PreviewWindowBackground.material(.ultraThick))
                Text("Bar").tag(PreviewWindowBackground.material(.bar))
                Divider()
                Text("Glass Clear").tag(PreviewWindowBackground.glass(.clear))
                Text("Glass Regular").tag(PreviewWindowBackground.glass(.regular))
            }

            Picker("Window Style", systemImage: "macwindow", selection: $windowStyle) {
                Text("Title Bar").tag(PreviewWindowStyle.titleBar)
                Text("Hidden Title Bar").tag(PreviewWindowStyle.hiddenTitleBar)
                Text("Toolbar").tag(PreviewWindowStyle.toolBar)
            }

            Picker("Appearance", systemImage: "circle.lefthalf.filled", selection: $colorSchemeOverride) {
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
                    .gesture(windowDragGesture)
                    .layoutPriority(1)
            } else {
                // Hidden title bar: transparent drag handle in safe area
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: windowStyle.safeAreaInsets.top)
                    .contentShape(.rect)
                    .overlay(alignment: .leading) {
                        if showTrafficLights {
                            TrafficLights()
                                .padding(.leading, 13)
                        }
                    }
                    .gesture(windowDragGesture)
            }
        }
        .windowFrame(windowSize)
    }

    private var showsTitleBar: Bool {
        windowStyle != .hiddenTitleBar
    }

    private var windowDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                let start = dragStartPosition ?? windowPosition
                dragStartPosition = start
                windowPosition = CGSize(width: start.width + value.translation.width,
                                        height: start.height + value.translation.height)
            }
            .onEnded { _ in
                dragStartPosition = nil
                let clamped = clampedPosition(windowPosition)
                if windowPosition != clamped {
                    withAnimation(.spring(duration: 0.3)) {
                        windowPosition = clamped
                    }
                }
            }
    }

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
        .background {
            if case .defaultStyle = backgroundStyle {
                ConcentricRectangle(corners: .concentric).fill(.bar)
            }
        }
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

    private func clampedPosition(_ position: CGSize) -> CGSize {
        let bound = wallpaperPadding - windowStyle.safeAreaInsets.top
        return CGSize(width: min(max(position.width, -bound), bound),
                      height: min(max(position.height, -bound), bound))
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
    func windowBackground(style: PreviewWindowBackground) -> some View {
        switch style {
        case .defaultStyle:
            self.background()
        case .clear:
            self.background(.clear)
        case .material(let variant):
            self.background(variant.material)
        case .glass(let variant):
            self.glassEffect(variant.glass, in: .containerRelative)
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
        .previewWindowPadding(100)
}

#endif // DEBUG

#endif // os(macOS)
