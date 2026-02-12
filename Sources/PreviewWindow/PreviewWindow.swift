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
    /// Toolbar-style window (like Safari) with 26pt corner radius.
    case toolBar
    /// Custom corner radius.
    case custom(CGFloat)

    var cornerRadius: CGFloat {
        switch self {
        case .titleBar: 16
        case .toolBar: 26
        case .custom(let radius): radius
        }
    }
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
/// }
/// ```
public struct PreviewWindow<Content: View>: View {
    let content: Content
    let wallpaper: AnyView?
    let windowSize: PreviewWindowSize
    let windowStyle: PreviewWindowStyle
    let windowMaterial: Material?
    let showTrafficLights: Bool
    let backgroundGlass: Glass?

    /// Creates a preview window chrome wrapper.
    /// - Parameters:
    ///   - windowSize: The size of the simulated window. Defaults to `.contentSize`.
    ///   - windowStyle: The window style determining corner radius. Defaults to `.titleBar` (16pt).
    ///   - windowMaterial: The material to use as window background, simulating `.containerBackground(material, for: .window)`. Defaults to
    /// `.thinMaterial`. Pass `nil` for a clear/transparent background.
    ///   - showTrafficLights: Whether to show the red/yellow/green traffic light buttons.
    ///   - wallpaper: Optional custom wallpaper view. Defaults to a macOS-style gradient.
    ///   - content: The view content to display inside the window.
    public init(windowSize: PreviewWindowSize = .contentSize,
                windowStyle: PreviewWindowStyle = .titleBar,
                windowMaterial: Material? = .thinMaterial,
                showTrafficLights: Bool = true,
                wallpaper: (some View)? = nil as EmptyView?,
                @ViewBuilder content: () -> Content) {
        self.windowSize = windowSize
        self.windowStyle = windowStyle
        self.windowMaterial = windowMaterial
        self.showTrafficLights = showTrafficLights
        self.wallpaper = wallpaper.map { AnyView($0) }
        self.content = content()
        self.backgroundGlass = nil
    }

    /// Creates a preview window chrome wrapper with a Liquid Glass background.
    /// - Parameters:
    ///   - windowSize: The size of the simulated window. Defaults to `.contentSize`.
    ///   - windowStyle: The window style determining corner radius. Defaults to `.titleBar` (16pt).
    ///   - backgroundGlass: The glass effect to apply as the window background.
    ///   - showTrafficLights: Whether to show the red/yellow/green traffic light buttons.
    ///   - wallpaper: Optional custom wallpaper view. Defaults to a macOS-style gradient.
    ///   - content: The view content to display inside the window.
    public init(windowSize: PreviewWindowSize = .contentSize,
                windowStyle: PreviewWindowStyle = .titleBar,
                backgroundGlass: Glass,
                showTrafficLights: Bool = true,
                wallpaper: (some View)? = nil as EmptyView?,
                @ViewBuilder content: () -> Content) {
        self.windowSize = windowSize
        self.windowStyle = windowStyle
        self.windowMaterial = nil
        self.showTrafficLights = showTrafficLights
        self.wallpaper = wallpaper.map { AnyView($0) }
        self.content = content()
        self.backgroundGlass = backgroundGlass
    }

    private let wallpaperPadding: CGFloat = 50

    public var body: some View {
        // Simulated window
        windowContent
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
                // Desktop wallpaper background
                Group {
                    if let wallpaper {
                        wallpaper
                    } else {
                        defaultWallpaper
                    }
                }
            }
            .clipped()
    }

    @ViewBuilder
    private var windowContent: some View {
        ZStack(alignment: .topLeading) {
            if let windowMaterial {
                framedContent
                    .background(windowMaterial)
            } else if let backgroundGlass {
                framedContent
                    .glassEffect(backgroundGlass, in: .containerRelative)
            } else {
                framedContent
            }

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

#Preview("TitleBar Style (16pt) - Clear Background") {
    PreviewWindow(windowMaterial: nil) {
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
        .padding(32)
    }
}

#Preview("TitleBar Style - Glass") {
    PreviewWindow(backgroundGlass: .regular) {
        VStack(alignment: .leading, spacing: 12) {
            Label("Notifications", systemImage: "bell.fill")
                .font(.headline)

            Toggle("Enable alerts", isOn: .constant(true))
            Toggle("Play sound", isOn: .constant(false))
            Toggle("Show badge", isOn: .constant(true))
        }
        .padding(24)
        .frame(width: 280)
    }
}

#Preview("Toolbar Style (26pt)") {
    PreviewWindow(windowStyle: .toolBar) {
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
        .padding(40)
    }
}

#Preview("Fixed Size") {
    PreviewWindow(windowSize: .fixed(width: 500, height: 350)) {
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
        .padding(.top, 28)
        .padding(24)
    }
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
        .padding(40)
    }
}
