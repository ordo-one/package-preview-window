# PreviewWindow

A SwiftUI preview wrapper that simulates macOS window chrome. Useful for previewing views that rely on window-level styling (`.containerBackground`, `.presentedWindowStyle(.hiddenTitleBar)`, etc.) which don't render in standard Xcode previews.

Renders a title bar, traffic lights, window border highlights, shadow, and a desktop wallpaper backdrop. The simulated window is draggable from the title bar and includes interactive controls for wallpaper, background, window style, and appearance.

<img width="1233" height="831" alt="image" src="https://github.com/user-attachments/assets/e447241b-4762-42b5-9e76-6046714bc1e6" />

**Requires macOS 26+, Swift 6.2+**

This package follows [Semantic Versioning](https://semver.org/). While the major version is `0`, the API is not yet considered stable and may change between minor releases.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ordo-one/package-preview-window", from: "0.1.0"),
]
```

Then add `"PreviewWindow"` to your target's dependencies.

## Usage

```swift
import PreviewWindow

#Preview {
    PreviewWindow {
        MyView()
    }
}
```

Configuration is applied through chainable modifiers — use only what you need:

### Window Size

```swift
// Fit to content (default)
PreviewWindow { ... }

// Fixed dimensions
PreviewWindow { ... }
    .previewWindowSize(.fixed(width: 500, height: 350))
```

### Window Style

```swift
// TitleBar style — 16pt corner radius (default)
PreviewWindow { ... }

// Toolbar style — 26pt corner radius (Safari-like)
PreviewWindow { ... }
    .previewWindowStyle(.toolBar)

// Hidden title bar — content extends behind transparent title bar
PreviewWindow { ... }
    .previewWindowStyle(.hiddenTitleBar)

// Custom corner radius
PreviewWindow { ... }
    .previewWindowStyle(.custom(20))
```

### Background

```swift
// System default (opaque)
PreviewWindow { ... }
    .previewWindowBackground(.defaultStyle)

// Material background
PreviewWindow { ... }
    .previewWindowBackground(.material(.thickMaterial))

// Glass background
PreviewWindow { ... }
    .previewWindowBackground(.glass(.regular))

// Clear (no background)
PreviewWindow { ... }
    .previewWindowBackground(.material(nil))
```

### Other Options

```swift
// Window title
PreviewWindow { ... }
    .previewWindowTitle("My App")

// Hide traffic lights
PreviewWindow { ... }
    .previewTrafficLights(false)

// Wallpaper style and appearance
PreviewWindow { ... }
    .previewWallpaper(.sunset, appearance: .dark)

// Custom desktop wallpaper
PreviewWindow(wallpaper: { MyWallpaper() }) {
    MyView()
}

// Combine multiple modifiers
PreviewWindow {
    MyView()
}
.previewWindowSize(.fixed(width: 500, height: 350))
.previewWindowStyle(.toolBar)
.previewWindowTitle("Settings")
.previewWindowBackground(.glass(.regular))
.previewWallpaper(.ocean, appearance: .dark)
```
