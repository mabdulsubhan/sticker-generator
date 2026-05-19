# SketchSticker

Draw something rough on your phone. Get a cute sticker back. No internet required after the first setup.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-black) ![Swift](https://img.shields.io/badge/Swift-6-orange) ![CoreML](https://img.shields.io/badge/CoreML-Stable%20Diffusion-purple)

---

## How it works

The app runs Stable Diffusion 1.5 entirely on-device using Apple's CoreML framework. Draw a sketch with your finger or Apple Pencil, pick a style, tap generate. If you have the ControlNet scribble model set up, the output actually follows your sketch. Without it, it falls back to img2img with lower strength.

Everything happens locally — no API calls, no data leaving your device.

## Setup

### Xcode

1. Clone the repo
2. Open `SketchSticker.xcodeproj`
3. File → Add Package Dependencies → `https://github.com/apple/ml-stable-diffusion`
4. Add `NSPhotoLibraryAddUsageDescription` to your target's Info tab
5. Run on a physical device (iPhone 12 or newer)

The simulator won't work — CoreML needs the Neural Engine for inference.

### Models

On first launch the app downloads ~600MB of CoreML models from Apple's HuggingFace repo (`apple/coreml-stable-diffusion-v1-5`). After that it's fully offline.

### ControlNet (optional but recommended)

Without ControlNet the app does img2img — it loosely follows your sketch. With it, the sketch directly conditions the generation so a fish stays a fish.

To set it up, run the Apple converter script:

```bash
pip install git+https://github.com/apple/ml-stable-diffusion
python -m python_coreml_stable_diffusion.torch2coreml \
  --model-version runwayml/stable-diffusion-v1-5 \
  --convert-unet --unet-support-controlnet \
  --convert-controlnet lllyasviel/sd-controlnet-scribble \
  --compute-unit CPU_AND_NE \
  --bundle-resources-for-swift-cli \
  -o ./output
```

Then copy from `output/Resources/`:
- `ControlledUnet.mlmodelc` → app's `Documents/SDModels/`
- `scribble.mlmodelc` → app's `Documents/SDModels/controlnet/`

The app auto-detects these on next launch and switches to ControlNet mode.

## Stack

- **SwiftUI + PencilKit** — drawing canvas
- **CoreML + [apple/ml-stable-diffusion](https://github.com/apple/ml-stable-diffusion)** — on-device inference
- **HuggingFace** — model download (first run only)
- **ControlNet scribble** — sketch-conditioned generation

## Requirements

- iPhone 12 or newer (A14 Bionic+)
- iOS 17.0+
- ~2GB free storage for models
- Xcode 16+
