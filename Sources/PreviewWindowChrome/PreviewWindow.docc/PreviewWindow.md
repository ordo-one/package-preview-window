# ``PreviewWindow``

Simulate macOS window chrome in SwiftUI previews.

## Overview

PreviewWindow wraps your views in a realistic macOS window frame — complete with a title bar, traffic lights, border highlights, shadow, and a desktop wallpaper backdrop. This is useful for previewing views that rely on window-level styling (`.containerBackground`, `.presentedWindowStyle(.hiddenTitleBar)`, etc.) which don't render in standard Xcode previews.

The simulated window is draggable from the title bar and snaps back if moved out of bounds. When using the default wallpaper, interactive pickers for wallpaper style, window style, background, and appearance are overlaid as a glass capsule.

![A fixed-size PreviewWindow showing a settings panel with traffic lights, material background, and desktop wallpaper.](fixed-size)

```swift
#Preview {
    PreviewWindow {
        MyView()
    }
}
```

Configuration is applied through chainable modifiers — use only what you need:

### Window Size

By default the window fits its content. Use ``PreviewWindowSize/fixed(width:height:)`` for explicit dimensions:

```swift
PreviewWindow {
    MyView()
}
.previewWindowSize(.fixed(width: 500, height: 350))
```

### Window Style

Choose a preset matching macOS Tahoe window styles:

```swift
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

Control the window background with the unified `.previewWindowBackground(_:)` modifier:

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

### Title and Wallpaper

```swift
PreviewWindow { ... }
    .previewWindowTitle("My App")
    .previewWallpaper(.sunset, appearance: .dark)
```

## Topics

### Essentials

- ``PreviewWindow``
- ``PreviewWindowSize``
- ``PreviewWindowStyle``
- ``PreviewWallpaper``
