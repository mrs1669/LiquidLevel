# LiquidLevel

[日本語](README.md) | **English**

A SwiftUI view that keeps its content horizontal relative to device tilt, **filling the container like a liquid** all the way to its lowest point.

When tilting the device, the container (the view's frame) appears diamond-shaped relative to gravity.
`LiquidView` not only counter-rotates the content, but also expands its size to reach the lowest vertex of this diamond, causing the content to sink just like liquid poured into a glass.

## Requirements

- iOS 17.0+
- Swift 6.0+ / Xcode 16+

## Installation

Add via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/mrs1669/LiquidLevel.git", from: "0.1.0"),
]
```

## Usage

```swift
import LiquidLevel

struct ContentView: View {
    var body: some View {
        LiquidView {
            Text("Liquid")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .frame(width: 240, height: 320)
    }
}
```

The content is provided with the dimensions of the tilted container's "horizontal bounding box".
Aligning to the bottom with `alignment: .bottom` allows the content to settle at the lowest vertex of the diamond when the device is tilted.

### Content Modes

```swift
// Default. Expands to the horizontal bounding box of the tilted container, filling it completely.
LiquidView(contentMode: .fill) { ... }

// Inscribes the content inside the container while preserving the container's aspect ratio. The entire content remains visible.
LiquidView(contentMode: .fit) { ... }

// Fills 40% of the container's area with liquid settling at the bottom with a horizontal surface line.
LiquidView(contentMode: .waterline(0.4)) {
    Color.blue
}
```

With `.waterline`, the content is given a horizontal rectangle covering the "region below the water surface" (width matches the horizontal bounding box, height matches the water level). Aligning with `alignment: .top` arranges elements along the water surface.
Binding the fraction to `@State` will also animate changes in water level.

### Customizing Animations

```swift
// Default is a spring animation that settles after a slight oscillation (Animation.liquid)
LiquidView(animation: .smooth) { ... }

// Follow sensor readings immediately without animation
LiquidView(animation: nil) { ... }

// Apply a low-pass filter to the sensor readings (0...0.99)
LiquidView(smoothing: 0.8) { ... }
```

### Fixed Tilt (for Previews and Simulator)

Since CoreMotion does not run on the simulator, an initializer accepting a direct `tilt` value is provided.

```swift
LiquidView(tilt: .degrees(30)) {
    Text("Liquid")
}
```

### Direct Motion Sensor Access & Sharing

`LiquidMotion` can also be used as a standalone `@Observable` model.
Passing it to `LiquidView(motion:)` allows multiple views to share sensor data or display the tilt value in other parts of the UI (in this case, `start()` and `stop()` are managed by the caller).

```swift
@State private var motion = LiquidMotion()

var body: some View {
    VStack {
        LiquidView(motion: motion) { Color.blue }
        Text("\(motion.tilt.degrees)°")
    }
    .onAppear { motion.start() }
    .onDisappear { motion.stop() }
}
```

## How It Works

1. Computes the device tilt angle $\phi$ via `atan2(gx, -gy)` using the `gravity` vector from `CMMotionManager`.
2. Converts the gravity vector to screen coordinates based on `windowScene.interfaceOrientation`.
3. Unwraps angles across the $\pm 180^\circ$ boundary to prevent sudden reverse rotation, and retains the previous value when the device is held roughly horizontal.
4. Rotates the content by $-\phi$, expands its size to the horizontal bounding box `(w|cos φ| + h|sin φ|, w|sin φ| + h|cos φ|)` centered within the container, and clips it to the container's bounds.
   - `.fit` solves the inverse inequalities to find the maximum horizontal inscribed rectangle.
   - `.waterline` computes the water level in closed form by calculating the area below height $y$ in a tilted rectangle as a piecewise function and inverting it.

Geometric calculations are isolated as pure functions in `LiquidGeometry` and thoroughly tested with Swift Testing.

## Testing

LiquidLevel is an iOS-specific package, so specify a simulator destination when running tests:

```bash
xcodebuild test -scheme LiquidLevel -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Demo App

Open `Example/LiquidLevelExample.xcodeproj` and run it on a physical device to inspect tilt/interface orientation readings, switch modes, and test behavior using the manual tilt slider (use the manual tilt slider on the simulator as CoreMotion is unavailable).
The Xcode project is generated using [XcodeGen](https://github.com/yonaskolb/XcodeGen). If you modify the configuration, regenerate it with:

```bash
cd Example && xcodegen generate
```

## Notes

- Accelerometer and gyroscope data from CoreMotion do not require an Info.plist permission entry (`NSMotionUsageDescription`).
- Motion tracking responds only on physical devices. For testing on the simulator, use the `tilt:` initializer or the demo app's manual slider.

## License

MIT
