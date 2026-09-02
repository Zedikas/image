# ImageMagick iOS

A native SwiftUI iOS application using the upstream ImageMagick C engine through `MagickWand`.

## Current implementation

- Native SwiftUI interface
- PhotosPicker image import
- CoreGraphics/Apple ImageIO decode path
- ImageMagick `MagickWand` processing
- Resize + sharpen example operation
- Q8, non-HDRI static ImageMagick build
- Separate device and simulator libraries
- Codemagic unsigned and signed workflows

The app deliberately uses Apple frameworks for image container I/O and feeds raw RGBA pixels into ImageMagick. This avoids depending on desktop-only dynamic delegates inside the iOS sandbox while retaining ImageMagick's processing engine.

## Upstream source

The build fetches the upstream `ImageMagick/ImageMagick` repository at build time. No modified copy of ImageMagick is embedded in this project.

## Build

Codemagic runs `scripts/build_imagemagick_ios.sh`, then builds `ImageMagickApp.xcodeproj`.

For local Xcode development, run the build script on a Mac first.

## Important

This is a real native integration scaffold, but the ImageMagick cross-compilation step is intentionally isolated in `scripts/build_imagemagick_ios.sh`. The first CI build is the integration validation point for the current ImageMagick release and current Xcode SDK.
