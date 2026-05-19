import Foundation

enum StickerStyle: String, CaseIterable, Identifiable {
    case kawaii, chibi, pixel, pastel

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kawaii: "Kawaii"
        case .chibi: "Chibi"
        case .pixel: "Pixel"
        case .pastel: "Pastel"
        }
    }

    var emoji: String {
        switch self {
        case .kawaii: "🌸"
        case .chibi: "🎀"
        case .pixel: "🎮"
        case .pastel: "🍬"
        }
    }

    var prompt: String {
        let base = "cute cartoon sticker, white background, thick black outline, isolated on white, clean illustration"
        switch self {
        case .kawaii: return "\(base), kawaii pastel colors, soft shading, adorable, round shapes"
        case .chibi: return "\(base), chibi cartoon style, bold outlines, flat colors, super cute"
        case .pixel: return "\(base), pixel art, 8-bit retro game sprite, crisp pixels, limited palette"
        case .pastel: return "\(base), soft pastel watercolor, gentle dreamy tones, hand-drawn"
        }
    }

    var negativePrompt: String {
        "ugly, blurry, low quality, realistic, photograph, dark background, human, person, girl, boy, woman, man, face, body, text, watermark"
    }
}
