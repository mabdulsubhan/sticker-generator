import Foundation
import Combine

@MainActor
final class ModelDownloader: ObservableObject {
    enum State: Equatable {
        case idle
        case fetchingManifest
        case downloading(file: String, fileIndex: Int, fileCount: Int)
        case done
        case error(String)
    }

    @Published var state: State = .idle
    @Published var overallProgress: Double = 0

    private let repoID = "apple/coreml-stable-diffusion-v1-5"
    private let subdir = "split_einsum/compiled"
    let destinationURL: URL

    init(destinationURL: URL) {
        self.destinationURL = destinationURL
    }

    func startDownload() {
        Task { await download() }
    }

    private struct HFEntry: Decodable {
        let type: String
        let path: String
        let size: Int64?
        let lfs: LFSInfo?

        struct LFSInfo: Decodable {
            let size: Int64?
        }
    }

    private func download() async {
        state = .fetchingManifest
        overallProgress = 0

        do {
            let files = try await fetchAllFiles(under: subdir)
            guard !files.isEmpty else {
                state = .error("No model files found in repository")
                return
            }

            try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)

            for (index, entry) in files.enumerated() {
                let relativePath = String(entry.path.dropFirst(subdir.count + 1))
                let dest = destinationURL.appendingPathComponent(relativePath)

                let displayName = URL(fileURLWithPath: relativePath).lastPathComponent
                state = .downloading(file: displayName, fileIndex: index + 1, fileCount: files.count)

                try FileManager.default.createDirectory(
                    at: dest.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                if FileManager.default.fileExists(atPath: dest.path) {
                    overallProgress = Double(index + 1) / Double(files.count)
                    continue
                }

                let downloadURL = hfURL(path: entry.path)
                let (tempURL, _) = try await URLSession.shared.download(from: downloadURL)

                try FileManager.default.moveItem(at: tempURL, to: dest)
                overallProgress = Double(index + 1) / Double(files.count)
            }

            state = .done
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func fetchAllFiles(under path: String) async throws -> [HFEntry] {
        let apiURL = URL(string: "https://huggingface.co/api/models/\(repoID)/tree/main/\(path)")!
        let (data, response) = try await URLSession.shared.data(from: apiURL)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        let entries = try JSONDecoder().decode([HFEntry].self, from: data)
        var files: [HFEntry] = []

        for entry in entries {
            if entry.type == "file" {
                files.append(entry)
            } else if entry.type == "directory" {
                let nested = try await fetchAllFiles(under: entry.path)
                files.append(contentsOf: nested)
            }
        }

        return files
    }

    private func hfURL(path: String) -> URL {
        URL(string: "https://huggingface.co/\(repoID)/resolve/main/\(path)")!
    }
}
