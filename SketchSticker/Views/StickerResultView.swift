import SwiftUI

struct StickerResultView: View {
    let image: UIImage
    @ObservedObject var generator: StickerGenerator
    @Environment(\.dismiss) private var dismiss

    @State private var saved = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                // Sticker preview
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .shadow(color: .purple.opacity(0.2), radius: 30, y: 10)
                    .transition(.scale.combined(with: .opacity))

                Text("Your Sticker is Ready! 🎉")
                    .font(.title2.bold())

                Spacer()

                // Actions
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            saveToPhotos()
                        } label: {
                            Label(saved ? "Saved!" : "Save to Photos",
                                  systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(saved ? .green : .blue)
                        .controlSize(.large)
                        .animation(.easeInOut, value: saved)

                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview("Sticker", image: Image(uiImage: image))
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .controlSize(.large)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Label("Draw Another", systemImage: "pencil.and.scribble")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Sticker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Save Failed", isPresented: .init(get: { saveError != nil }, set: { _ in saveError = nil })) {
                Button("OK") {}
            } message: {
                Text(saveError ?? "")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func saveToPhotos() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        withAnimation { saved = true }
    }
}
