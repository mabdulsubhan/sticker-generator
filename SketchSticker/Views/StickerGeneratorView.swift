import SwiftUI
import PencilKit

struct StickerGeneratorView: View {
    @ObservedObject var generator: StickerGenerator
    @State private var canvasView = PKCanvasView()
    @State private var selectedStyle: StickerStyle = .kawaii
    @State private var strokeWidth: CGFloat = 8
    @State private var strokeColor: UIColor = .black
    @State private var resultImage: UIImage?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                canvasArea
                    .padding(.horizontal)
                    .padding(.top, 8)

                controlsArea
            }
            .navigationTitle("Sketch Sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", systemImage: "trash") {
                        canvasView.drawing = PKDrawing()
                    }
                    .tint(.red)
                    .disabled(canvasView.drawing.strokes.isEmpty)
                }
            }
            .overlay { generatingOverlay }
            .sheet(item: $resultImage) { image in
                StickerResultView(image: image, generator: generator)
                    .onDisappear { generator.resetToReady() }
            }
            .alert("Generation Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil; generator.resetToReady() } }
            )) {
                Button("OK") { errorMessage = nil; generator.resetToReady() }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: generator.phase) { _, phase in
                switch phase {
                case .result(let img): resultImage = img
                case .error(let msg): errorMessage = msg
                default: break
                }
            }
        }
    }

    private var canvasArea: some View {
        ZStack {
            DrawingCanvasView(canvasView: $canvasView, strokeColor: strokeColor, strokeWidth: strokeWidth)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.purple.opacity(0.25), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)

            if canvasView.drawing.strokes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple.opacity(0.4))
                    Text("Draw something cute!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .allowsHitTesting(false)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var controlsArea: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Style")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(StickerStyle.allCases) { style in
                            StyleChip(style: style, isSelected: selectedStyle == style) {
                                selectedStyle = style
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)

                Slider(value: $strokeWidth, in: 3...20, step: 1)
                    .tint(.purple)

                Image(systemName: "circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                Divider().frame(height: 24)

                ColorPicker("", selection: Binding(
                    get: { Color(strokeColor) },
                    set: { strokeColor = UIColor($0) }
                ))
                .labelsHidden()
            }
            .padding(.horizontal)

            Button {
                let sketch = canvasView.exportImage()
                generator.generate(sketch: sketch, style: selectedStyle)
            } label: {
                Label("Generate Sticker", systemImage: "wand.and.stars.inverse")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)
            .disabled(canvasView.drawing.strokes.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var generatingOverlay: some View {
        if case .generating(let progress) = generator.phase {
            ZStack {
                Color.black.opacity(0.45).ignoresSafeArea()

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 6)
                            .frame(width: 64, height: 64)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.purple, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 64, height: 64)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.2), value: progress)
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.white)
                            .font(.title3)
                    }

                    VStack(spacing: 4) {
                        Text("Generating sticker…")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    if progress < 0.05 {
                        Text("Loading model (first run may take a minute)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 220)
                    }
                }
                .padding(32)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            }
        }
    }
}

struct StyleChip: View {
    let style: StickerStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(style.emoji)
                Text(style.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

extension UIImage: @retroactive Identifiable {
    public var id: ObjectIdentifier { ObjectIdentifier(self) }
}
