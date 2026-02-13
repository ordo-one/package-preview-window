# ``PreviewWindow``

Simulate macOS window chrome in SwiftUI previews.

## Overview

PreviewWindow wraps your views in a realistic macOS window frame — complete with traffic lights, border highlights, shadow, and a desktop wallpaper backdrop. This is useful for previewing views that rely on window-level styling (`.containerBackground`, `.presentedWindowStyle(.hiddenTitleBar)`, etc.) which don't render in standard Xcode previews.

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

Choose a corner radius preset matching macOS Tahoe window styles:

```swift
// Toolbar style — 26pt corner radius
PreviewWindow { ... }
    .previewWindowStyle(.toolBar)

// Custom corner radius
PreviewWindow { ... }
    .previewWindowStyle(.custom(20))
```

### Background

Control the window background material or use Liquid Glass:

```swift
// Material background (default: .thinMaterial)
PreviewWindow { ... }
    .previewWindowMaterial(.thickMaterial)

// Glass background
PreviewWindow { ... }
    .previewBackgroundGlass(.regular)

// No background
PreviewWindow { ... }
    .previewWindowMaterial(nil)
```

## Topics

### Essentials

- ``PreviewWindow``
- ``PreviewWindowSize``
- ``PreviewWindowStyle``
