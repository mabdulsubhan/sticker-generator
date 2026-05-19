import SwiftUI
import PencilKit

struct DrawingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    var strokeColor: UIColor
    var strokeWidth: CGFloat

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .white
        canvasView.isOpaque = true
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: strokeColor, width: strokeWidth)
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.tool = PKInkingTool(.pen, color: strokeColor, width: strokeWidth)
    }
}

extension PKCanvasView {
    func exportImage() -> UIImage {
        let bounds = bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            drawing.image(from: bounds, scale: UIScreen.main.scale).draw(in: bounds)
        }
    }
}
