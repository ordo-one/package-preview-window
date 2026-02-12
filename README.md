# PreviewWindow

A SwiftUI preview wrapper that simulates macOS window chrome. Useful for previewing views that rely on window-level styling (`.containerBackground`, `.presentedWindowStyle(.hiddenTitleBar)`, etc.) which don't render in standard Xcode previews.

Renders traffic lights, window border highlights, shadow, and a desktop wallpaper backdrop.

**Requires macOS 26+, Swift 6.2+**

This package follows [Semantic Versioning](https://semver.org/). While the major version is `0`, the API is not yet considered stable and may change between minor releases.

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ordo-one/package-preview-window", from: "0.0.1"),
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

### Window Size

```swift
// Fit to content (default)
PreviewWindow { ... }

// Fixed dimensions
PreviewWindow(windowSize: .fixed(width: 500, height: 350)) { ... }
```

### Window Style

```swift
// TitleBar style — 16pt corner radius (default)
PreviewWindow(windowStyle: .titleBar) { ... }

// Toolbar style — 26pt corner radius (Safari-like)
PreviewWindow(windowStyle: .toolBar) { ... }

// Custom corner radius
PreviewWindow(windowStyle: .custom(20)) { ... }
```

### Background

```swift
// Material background (default: .thinMaterial)
PreviewWindow(windowMaterial: .thickMaterial) { ... }

// Glass background
PreviewWindow(backgroundGlass: .regular) { ... }

// No background
PreviewWindow(windowMaterial: nil) { ... }
```

### Other Options

```swift
PreviewWindow(
    showTrafficLights: false,    // Hide the red/yellow/green buttons
    wallpaper: { MyWallpaper() } // Custom desktop wallpaper
) {
    MyView()
}
```
