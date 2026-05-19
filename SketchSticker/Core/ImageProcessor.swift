import UIKit
import CoreGraphics
import CoreImage

enum ImageProcessor {
    static let modelSize = CGSize(width: 512, height: 512)

    static func prepare(sketch: UIImage) -> CGImage? {
        squareBGRA(from: sketch)
    }

    static func prepareControlNetInput(sketch: UIImage) -> CGImage? {
        guard let base = squareBGRA(from: sketch) else { return nil }
        let inverted = CIImage(cgImage: base).applyingFilter("CIColorInvert")
        return CIContext(options: [.useSoftwareRenderer: false]).createCGImage(inverted, from: inverted.extent)
    }

    static func makeSticker(from image: UIImage) -> UIImage {
        let border: CGFloat = 14
        let newSize = CGSize(width: image.size.width + border * 2, height: image.size.height + border * 2)
        return UIGraphicsImageRenderer(size: newSize).image { ctx in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: newSize), cornerRadius: border * 1.5)
            ctx.cgContext.setShadow(offset: CGSize(width: 0, height: 3), blur: 8, color: UIColor.black.withAlphaComponent(0.2).cgColor)
            UIColor.white.setFill()
            path.fill()
            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            image.draw(in: CGRect(x: border, y: border, width: image.size.width, height: image.size.height))
        }
    }

    private static func squareBGRA(from sketch: UIImage) -> CGImage? {
        let w = Int(modelSize.width), h = Int(modelSize.height)
        guard let ctx = CGContext(
            data: nil, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        let size = sketch.size
        let side = min(size.width, size.height)
        let cropRect = CGRect(
            x: (size.width - side) / 2 * sketch.scale,
            y: (size.height - side) / 2 * sketch.scale,
            width: side * sketch.scale,
            height: side * sketch.scale
        )

        if let cg = sketch.cgImage, let cropped = cg.cropping(to: cropRect) {
            ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: w, height: h))
        } else {
            UIGraphicsPushContext(ctx)
            sketch.draw(in: CGRect(x: 0, y: 0, width: w, height: h))
            UIGraphicsPopContext()
        }

        return ctx.makeImage()
    }
}
