import Foundation
import Combine
import CoreML
import UIKit
import StableDiffusion

private final class Pipeline: @unchecked Sendable {
    let sd: StableDiffusionPipeline
    let hasControlNet: Bool

    init(_ sd: StableDiffusionPipeline, hasControlNet: Bool = false) {
        self.sd = sd
        self.hasControlNet = hasControlNet
    }

    func generate(config: StableDiffusionPipeline.Configuration, onStep: @Sendable @escaping (Int, Int) -> Bool) throws -> [CGImage?] {
        try sd.generateImages(configuration: config) { onStep($0.step, $0.stepCount) }
    }
}

@MainActor
final class StickerGenerator: ObservableObject {
    enum Phase {
        case needsSetup
        case downloading
        case ready
        case generating(progress: Double)
        case result(UIImage)
        case error(String)
    }

    @Published var phase: Phase = .needsSetup
    @Published var downloader: ModelDownloader

    var isSetup: Bool {
        switch phase {
        case .needsSetup, .downloading: false
        default: true
        }
    }

    let modelsRootURL: URL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SDModels", isDirectory: true)

    private var pipeline: Pipeline?

    init() {
        downloader = ModelDownloader(destinationURL: FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SDModels", isDirectory: true))
        checkModels()
    }

    func resolvedModelsURL() -> URL? {
        let fm = FileManager.default

        func valid(_ url: URL) -> Bool {
            ["TextEncoder.mlmodelc", "VAEDecoder.mlmodelc"].allSatisfy {
                fm.fileExists(atPath: url.appendingPathComponent($0).path)
            }
        }

        if valid(modelsRootURL) { return modelsRootURL }

        let dirs = (try? fm.contentsOfDirectory(at: modelsRootURL, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        for dir in dirs where dir.hasDirectoryPath {
            if valid(dir) { return dir }
            let inner = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
            if let found = inner.first(where: { $0.hasDirectoryPath && valid($0) }) { return found }
        }
        return nil
    }

    func checkModels() {
        phase = resolvedModelsURL() != nil ? .ready : .needsSetup
    }

    func beginDownload() {
        phase = .downloading
        downloader.startDownload()
        Task {
            for await state in downloader.$state.values {
                switch state {
                case .done: checkModels()
                case .error(let msg): phase = .error(msg)
                default: break
                }
            }
        }
    }

    func generate(sketch: UIImage, style: StickerStyle) {
        guard case .ready = phase else { return }
        Task { await runGeneration(sketch: sketch, style: style) }
    }

    func resetToReady() {
        phase = .ready
    }

    func controlNetAvailable() -> Bool {
        guard let url = resolvedModelsURL() else { return false }
        return FileManager.default.fileExists(atPath: url.appendingPathComponent("controlnet/scribble.mlmodelc").path)
    }

    private func runGeneration(sketch: UIImage, style: StickerStyle) async {
        phase = .generating(progress: 0)

        do {
            let usingControlNet = controlNetAvailable()

            if pipeline == nil || pipeline?.hasControlNet != usingControlNet {
                phase = .generating(progress: 0.02)
                pipeline = nil
                pipeline = try await loadPipeline(controlNet: usingControlNet)
            }

            guard let pipeline else {
                phase = .error("Pipeline unavailable")
                return
            }

            var config = StableDiffusionPipeline.Configuration(prompt: style.prompt)
            config.negativePrompt = style.negativePrompt
            config.stepCount = 30
            config.seed = UInt32.random(in: 0...UInt32.max)
            config.guidanceScale = 8.5
            config.schedulerType = .dpmSolverMultistepScheduler

            if usingControlNet {
                guard let input = ImageProcessor.prepareControlNetInput(sketch: sketch) else {
                    phase = .error("Failed to prepare ControlNet input")
                    return
                }
                config.controlNetInputs = [input]
            } else {
                guard let start = ImageProcessor.prepare(sketch: sketch) else {
                    phase = .error("Failed to process sketch")
                    return
                }
                config.startingImage = start
                config.strength = 0.40
            }

            let (progressStream, cont) = AsyncStream.makeStream(of: Double.self)
            Task { @MainActor [weak self] in
                for await p in progressStream { self?.phase = .generating(progress: p) }
            }

            let results: [CGImage?] = try await Task.detached(priority: .userInitiated) {
                defer { cont.finish() }
                return try pipeline.generate(config: config) { step, total in
                    cont.yield(Double(step) / Double(max(total, 1)))
                    return true
                }
            }.value

            guard let cgImage = results.first, let cgImage else {
                phase = .error("Generation produced no image")
                return
            }

            phase = .result(ImageProcessor.makeSticker(from: UIImage(cgImage: cgImage)))

        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    private func loadPipeline(controlNet: Bool) async throws -> Pipeline {
        guard let url = resolvedModelsURL() else {
            throw NSError(domain: "SketchSticker", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model directory not found"])
        }
        return try await Task.detached(priority: .userInitiated) {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let pipe = try StableDiffusionPipeline(
                resourcesAt: url,
                controlNet: controlNet ? ["scribble"] : [],
                configuration: config,
                disableSafety: true,
                reduceMemory: true
            )
            try pipe.loadResources()
            return Pipeline(pipe, hasControlNet: controlNet)
        }.value
    }
}

extension StickerGenerator.Phase: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.needsSetup, .needsSetup), (.downloading, .downloading), (.ready, .ready), (.result, .result): true
        case (.generating(let a), .generating(let b)): a == b
        case (.error(let a), .error(let b)): a == b
        default: false
        }
    }
}
