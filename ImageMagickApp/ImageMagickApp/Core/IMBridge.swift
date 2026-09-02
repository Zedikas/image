import Foundation
import UIKit
import ImageIO
import CoreGraphics

enum IMBridgeError: LocalizedError {
    case cannotCreateCGImage
    case processingFailed(String)
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .cannotCreateCGImage: return "Could not decode the selected image."
        case .processingFailed(let message): return message
        case .invalidOutput: return "ImageMagick returned invalid image data."
        }
    }
}

enum IMBridge {
    static func version() -> String {
        String(cString: IMBridgeVersion())
    }

    static func resizeAndSharpen(image: UIImage, width: Int) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw IMBridgeError.cannotCreateCGImage
        }

        let sourceWidth = cgImage.width
        let sourceHeight = cgImage.height
        var rgba = [UInt8](repeating: 0, count: sourceWidth * sourceHeight * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &rgba,
            width: sourceWidth,
            height: sourceHeight,
            bitsPerComponent: 8,
            bytesPerRow: sourceWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw IMBridgeError.cannotCreateCGImage
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: sourceWidth, height: sourceHeight))

        let processed = rgba.withUnsafeBufferPointer { buffer in
            IMBridgeResizeAndSharpen(buffer.baseAddress, UInt(sourceWidth), UInt(sourceHeight), UInt(width))
        }

        guard let bytes = processed.bytes, processed.length > 0 else {
            throw IMBridgeError.processingFailed(String(cString: IMBridgeLastError()))
        }
        defer { IMBridgeFreeImage(processed) }

        guard let provider = CGDataProvider(data: Data(bytes: bytes, count: processed.length) as CFData),
              let outputCG = CGImage(
                width: Int(processed.width),
                height: Int(processed.height),
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: Int(processed.width) * 4,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            throw IMBridgeError.invalidOutput
        }

        return UIImage(cgImage: outputCG, scale: image.scale, orientation: image.imageOrientation)
    }
}
