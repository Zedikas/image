# Build status

This archive contains the native iOS project, SwiftUI frontend, C/Swift bridge,
and Codemagic cross-compilation pipeline.

The iOS build itself has not been executed in this Linux environment because
Xcode/iPhoneOS SDKs are required. The first Codemagic run is therefore the
required integration validation step.

Expected pipeline:
1. Clone ImageMagick from upstream.
2. Cross-compile Q8/non-HDRI static libraries for arm64 iPhoneOS and arm64 iOS Simulator.
3. Build `ImageMagickApp.xcodeproj`.
4. Produce an unsigned `.app` or, with signing configured, an `.ipa`.

The app currently demonstrates a real ImageMagick operation: resize + sharpen
on raw RGBA pixels supplied from Apple's image APIs.
