#if os(macOS)
import SwiftUI

/// The background style applied to the simulated window content area.
public enum PreviewWindowBackground: Hashable {
    /// System default background.
    case defaultStyle
    /// A clear (transparent) background.
    case clear
    /// A material blur background.
    case material(MaterialVariant)
    /// A Liquid Glass background.
    case glass(GlassVariant)

    /// Material blur variants available for the window background.
    public enum MaterialVariant: Hashable {
        case ultraThin, thin, regular, thick, ultraThick, bar

        var material: Material {
            switch self {
            case .ultraThin: .ultraThinMaterial
            case .thin: .thinMaterial
            case .regular: .regularMaterial
            case .thick: .thickMaterial
            case .ultraThick: .ultraThickMaterial
            case .bar: .bar
            }
        }
    }

    /// Liquid Glass variants available for the window background.
    public enum GlassVariant: Hashable {
        case clear, regular

        var glass: Glass {
            switch self {
            case .clear: .clear
            case .regular: .regular
            }
        }
    }
}

#endif // os(macOS)
