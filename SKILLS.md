# PreviewWindow — AI Coding Assistant Skill

Use this skill when writing or modifying SwiftUI `#Preview` blocks that use the `PreviewWindow` package. This package simulates macOS window chrome (title bar, traffic lights, borders, shadow, wallpaper) so views that depend on window-level styling render correctly in Xcode previews.

**Requires macOS 26+, Swift 6.2+. macOS only.**

## Import

```swift
import PreviewWindowChrome
```

## Basic Usage

Wrap any view in `PreviewWindow` inside a `#Preview`:

```swift
#Preview {
    PreviewWindow {
        MyView()
    }
}
```

## Modifiers

All modifiers are chainable. Use only what you need.

### Window Size

```swift
// Fit to content (default)
PreviewWindow { MyView() }

// Fixed dimensions
PreviewWindow { MyView() }
    .previewWindowSize(.fixed(width: 500, height: 350))
```

`PreviewWindowSize` cases: `.contentSize`, `.fixed(width:height:)`.

### Window Style

```swift
PreviewWindow { MyView() }
    .previewWindowStyle(.toolBar)
```

`PreviewWindowStyle` cases: `.titleBar` (default, 16pt radius), `.hiddenTitleBar` (16pt, transparent title bar), `.toolBar` (26pt, Safari-like), `.custom(CGFloat)`.

### Background

```swift
PreviewWindow { MyView() }
    .previewWindowBackground(.material(.bar))
```

`PreviewWindowBackground` cases:
- `.defaultStyle` — system default opaque background
- `.clear` — transparent, no background
- `.material(variant)` — material blur. `MaterialVariant`: `.ultraThin`, `.thin`, `.regular`, `.thick`, `.ultraThick`, `.bar`
- `.glass(variant)` — Liquid Glass. `GlassVariant`: `.clear`, `.regular`

### Title

```swift
PreviewWindow { MyView() }
    .previewWindowTitle("Settings")
```

### Traffic Lights

```swift
PreviewWindow { MyView() }
    .previewTrafficLights(false) // hide close/minimize/zoom buttons
```

### Wallpaper

```swift
PreviewWindow { MyView() }
    .previewWallpaper(.sunset, appearance: .dark)
```

`PreviewWallpaper.Style` cases: `.ocean` (default), `.sunset`, `.meadow`, `.solid`, `.highContrast`.

Appearance: `.dark` (default) or `.light`.

### Wallpaper Controls

The interactive control bar overlay is shown by default when using the built-in wallpaper. Hide it with:

```swift
PreviewWindow { MyView() }
    .previewWallpaperControls(false)
```

### Wallpaper Padding

```swift
PreviewWindow { MyView() }
    .previewWindowPadding(100) // default is 200
```

### Color Scheme Override

```swift
PreviewWindow { MyView() }
    .previewColorScheme(.dark)
```

### Custom Wallpaper

```swift
PreviewWindow(wallpaper: { MyCustomWallpaper() }) {
    MyView()
}
```

When using a custom wallpaper, the interactive control bar is automatically hidden.

## Full Example

```swift
#Preview {
    PreviewWindow {
        VStack {
            Text("Hello")
            Button("OK") {}
                .buttonStyle(.glassProminent)
        }
        .padding(20)
    }
    .previewWindowSize(.fixed(width: 400, height: 300))
    .previewWindowStyle(.hiddenTitleBar)
    .previewWindowBackground(.glass(.regular))
    .previewWindowTitle("My App")
    .previewWallpaper(.ocean, appearance: .dark)
}
```
