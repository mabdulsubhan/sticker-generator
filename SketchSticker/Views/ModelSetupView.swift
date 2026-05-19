import SwiftUI

struct ModelSetupView: View {
    @ObservedObject var generator: StickerGenerator

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
                            )

                        Text("AI Model Setup")
                            .font(.largeTitle.bold())

                        Text("Sketch Sticker runs a CoreML image model entirely on your device — no internet needed after setup.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    downloadCard

                    VStack(spacing: 2) {
                        InfoRow(icon: "cpu", label: "Model", value: "SD 2.1 Base (palettized)")
                        InfoRow(icon: "internaldrive", label: "Size", value: "~800 MB")
                        InfoRow(icon: "wifi.slash", label: "After setup", value: "Fully offline")
                        InfoRow(icon: "antenna.radiowaves.left.and.right", label: "Requires", value: "A14 Bionic or newer")
                    }
                    .padding(.horizontal)
                    .background(Color(.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    Button {
                        generator.checkModels()
                    } label: {
                        Label("I already have models — check again", systemImage: "arrow.clockwise")
                            .font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var downloadCard: some View {
        VStack(spacing: 16) {
            switch generator.downloader.state {
            case .idle, .fetchingManifest:
                idleContent
            case .downloading(let file, let idx, let count):
                downloadingContent(file: file, index: idx, count: count)
            case .done:
                doneContent
            case .error(let msg):
                errorContent(msg)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }

    private var idleContent: some View {
        VStack(spacing: 14) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 36))
                .foregroundStyle(.purple)

            VStack(spacing: 4) {
                Text("Download CoreML Model")
                    .font(.headline)
                Text("~800 MB · Wi-Fi recommended\nFrom apple/coreml-stable-diffusion on HuggingFace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                generator.beginDownload()
            } label: {
                Label("Download Now", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)
        }
    }

    private func downloadingContent(file: String, index: Int, count: Int) -> some View {
        VStack(spacing: 14) {
            ProgressView(value: generator.downloader.overallProgress)
                .tint(.purple)
                .scaleEffect(x: 1, y: 2)

            VStack(spacing: 4) {
                Text("Downloading \(index) of \(count)")
                    .font(.headline)
                Text(file)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(Int(generator.downloader.overallProgress * 100))% complete")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var doneContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)
            Text("Models ready!")
                .font(.headline)
            Button {
                generator.checkModels()
            } label: {
                Label("Continue", systemImage: "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
    }

    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("Download Failed")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                generator.beginDownload()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .controlSize(.large)
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        Divider().padding(.horizontal, 16)
    }
}
