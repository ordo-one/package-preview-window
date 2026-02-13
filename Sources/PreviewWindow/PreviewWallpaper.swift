import SwiftUI

/// A programmatic wallpaper that adapts to light and dark appearance.
///
/// Gradient styles layer geometric shapes filled with hue-preserving gradients
/// over a base gradient, producing hard edges visible through material and glass effects.
/// Additional utility styles (`.solid`, `.highContrast`) are provided for testing.
public struct PreviewWallpaper: View {
    /// Named wallpaper presets.
    public enum Style: Sendable {
        /// Cool blue gradient with layered shapes. Default style.
        case ocean
        /// Warm gold-to-magenta gradient with layered shapes.
        case sunset
        /// Green-to-teal gradient with layered shapes.
        case meadow
        /// Flat gray fill (light gray in light mode, dark gray in dark mode).
        case solid
        /// Split black and white halves for extreme contrast testing.
        case highContrast
    }

    let style: Style
    var appearanceOverride: ColorScheme?
    @Environment(\.colorScheme) private var environmentColorScheme

    /// Creates a wallpaper with the given style.
    public init(_ style: Style = .ocean) {
        self.style = style
    }

    /// Overrides the color scheme, ignoring the environment.
    public func appearance(_ colorScheme: ColorScheme) -> Self {
        var copy = self
        copy.appearanceOverride = colorScheme
        return copy
    }

    private var scheme: ColorScheme {
        appearanceOverride ?? environmentColorScheme
    }

    public var body: some View {
        if style == .solid {
            solidColor
        } else if style == .highContrast {
            HStack(spacing: 0) {
                Color.white
                Color.black
            }
        } else {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let colors = palette

                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: colors.base,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Large circle — top-left
                    Circle()
                        .fill(shapeGradient(colors.shapes[0], from: .top, to: .bottom))
                        .frame(width: w * 0.7, height: w * 0.7)
                        .offset(x: -w * 0.2, y: -h * 0.25)

                    // Tall ellipse — center-right
                    Ellipse()
                        .fill(shapeGradient(colors.shapes[1], from: .topLeading, to: .bottomTrailing))
                        .frame(width: w * 0.45, height: h * 0.8)
                        .offset(x: w * 0.25, y: h * 0.05)

                    // Rotated rounded rectangle — upper-center
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(shapeGradient(colors.shapes[2], from: .leading, to: .trailing))
                        .frame(width: w * 0.55, height: h * 0.28)
                        .rotationEffect(.degrees(-12))
                        .offset(x: w * 0.05, y: -h * 0.1)

                    // Medium circle — bottom-left
                    Circle()
                        .fill(shapeGradient(colors.shapes[3], from: .topTrailing, to: .bottomLeading))
                        .frame(width: w * 0.45, height: w * 0.45)
                        .offset(x: -w * 0.15, y: h * 0.3)

                    // Small ellipse — bottom-right accent
                    Ellipse()
                        .fill(shapeGradient(colors.shapes[4], from: .top, to: .bottom))
                        .frame(width: w * 0.38, height: h * 0.32)
                        .offset(x: w * 0.28, y: h * 0.35)
                }
            }
        }
    }

    private var solidColor: Color {
        scheme == .dark ? Color(white: 0.2) : Color(white: 0.82)
    }

    /// Creates a gradient from a shape color by mixing with white (bright end)
    /// and black (dim end), keeping the same hue while shifting saturation and luminosity.
    private func shapeGradient(_ color: Color, from start: UnitPoint, to end: UnitPoint) -> LinearGradient {
        LinearGradient(
            colors: [
                color.mix(with: .white, by: 0.35),
                color.mix(with: .black, by: 0.30),
            ],
            startPoint: start,
            endPoint: end
        )
    }

    // MARK: - Palette

    private struct Palette {
        let base: [Color]
        let shapes: [Color]
    }

    private var palette: Palette {
        switch (style, scheme) {

        // MARK: Sunset
        case (.sunset, .light):
            Palette(
                base: [
                    Color(red: 1.00, green: 0.82, blue: 0.40),
                    Color(red: 0.78, green: 0.18, blue: 0.48),
                ],
                shapes: [
                    Color(red: 0.98, green: 0.60, blue: 0.25).opacity(0.75),
                    Color(red: 0.92, green: 0.30, blue: 0.40).opacity(0.70),
                    Color(red: 1.00, green: 0.75, blue: 0.30).opacity(0.55),
                    Color(red: 0.75, green: 0.20, blue: 0.55).opacity(0.65),
                    Color(red: 0.88, green: 0.42, blue: 0.32).opacity(0.60),
                ]
            )
        case (.sunset, .dark):
            Palette(
                base: [
                    Color(red: 0.38, green: 0.16, blue: 0.06),
                    Color(red: 0.32, green: 0.05, blue: 0.22),
                ],
                shapes: [
                    Color(red: 0.55, green: 0.22, blue: 0.04).opacity(0.85),
                    Color(red: 0.48, green: 0.10, blue: 0.18).opacity(0.75),
                    Color(red: 0.52, green: 0.28, blue: 0.08).opacity(0.60),
                    Color(red: 0.38, green: 0.06, blue: 0.30).opacity(0.70),
                    Color(red: 0.45, green: 0.12, blue: 0.12).opacity(0.65),
                ]
            )

        // MARK: Ocean
        case (.ocean, .light):
            Palette(
                base: [
                    Color(red: 0.42, green: 0.85, blue: 0.95),
                    Color(red: 0.10, green: 0.30, blue: 0.75),
                ],
                shapes: [
                    Color(red: 0.28, green: 0.82, blue: 0.80).opacity(0.70),
                    Color(red: 0.12, green: 0.45, blue: 0.88).opacity(0.65),
                    Color(red: 0.50, green: 0.90, blue: 0.92).opacity(0.50),
                    Color(red: 0.08, green: 0.35, blue: 0.65).opacity(0.70),
                    Color(red: 0.20, green: 0.60, blue: 0.85).opacity(0.55),
                ]
            )
        case (.ocean, .dark):
            Palette(
                base: [
                    Color(red: 0.04, green: 0.16, blue: 0.32),
                    Color(red: 0.02, green: 0.06, blue: 0.28),
                ],
                shapes: [
                    Color(red: 0.08, green: 0.35, blue: 0.42).opacity(0.80),
                    Color(red: 0.04, green: 0.18, blue: 0.48).opacity(0.70),
                    Color(red: 0.12, green: 0.40, blue: 0.38).opacity(0.55),
                    Color(red: 0.02, green: 0.12, blue: 0.40).opacity(0.75),
                    Color(red: 0.06, green: 0.25, blue: 0.45).opacity(0.60),
                ]
            )

        // MARK: Meadow
        case (.meadow, .light):
            Palette(
                base: [
                    Color(red: 0.55, green: 0.90, blue: 0.38),
                    Color(red: 0.18, green: 0.58, blue: 0.68),
                ],
                shapes: [
                    Color(red: 0.70, green: 0.92, blue: 0.30).opacity(0.70),
                    Color(red: 0.25, green: 0.72, blue: 0.60).opacity(0.65),
                    Color(red: 0.48, green: 0.88, blue: 0.42).opacity(0.55),
                    Color(red: 0.15, green: 0.50, blue: 0.55).opacity(0.70),
                    Color(red: 0.35, green: 0.78, blue: 0.48).opacity(0.60),
                ]
            )
        case (.meadow, .dark):
            Palette(
                base: [
                    Color(red: 0.08, green: 0.26, blue: 0.06),
                    Color(red: 0.04, green: 0.16, blue: 0.22),
                ],
                shapes: [
                    Color(red: 0.18, green: 0.42, blue: 0.08).opacity(0.80),
                    Color(red: 0.06, green: 0.32, blue: 0.28).opacity(0.70),
                    Color(red: 0.14, green: 0.38, blue: 0.10).opacity(0.60),
                    Color(red: 0.03, green: 0.22, blue: 0.24).opacity(0.75),
                    Color(red: 0.10, green: 0.35, blue: 0.16).opacity(0.65),
                ]
            )

        default:
            Palette(
                base: [Color.gray],
                shapes: Array(repeating: Color.gray.opacity(0.5), count: 5)
            )
        }
    }
}
