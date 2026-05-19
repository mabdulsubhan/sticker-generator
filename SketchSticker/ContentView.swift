import SwiftUI

struct ContentView: View {
    @StateObject private var generator = StickerGenerator()

    var body: some View {
        Group {
            switch generator.phase {
            case .needsSetup, .downloading:
                ModelSetupView(generator: generator)
            default:
                StickerGeneratorView(generator: generator)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: generator.isSetup)
    }
}
