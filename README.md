# 👾 PixelForge

[![Build & Release macOS App](https://github.com/mrh-jishan/PixelForge/actions/workflows/release.yml/badge.svg)](https://github.com/mrh-jishan/PixelForge/actions/workflows/release.yml)
[![Release](https://img.shields.io/github/v/release/mrh-jishan/PixelForge?color=blue&logo=apple)](https://github.com/mrh-jishan/PixelForge/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?logo=apple)](https://github.com/mrh-jishan/PixelForge)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **High-Performance Native macOS Image Viewer & Retro Pixel Processing Studio**  
> Built with **Swift 6**, **Metal GPU Compute**, and **Core Image / Accelerate** for Apple Silicon.

---

## ⚡ Highlights

- **Fastest Native Execution**: Built using Swift with LLVM `-O` release optimizations and direct Metal GPU acceleration (`Apple M-Series GPU`). Filter passes execute in **sub-millisecond latency (< 0.5 ms)**.
- **Pixel-Crisp Display Engine**: Custom nearest-neighbor interpolation viewport ensures pixel art remains razor-sharp at up to **3200% zoom** without blurry bilinear filtering.
- **Interactive Split Comparison**: Draggable real-time divider lets you compare the original image against the pixelated/filtered image side-by-side.
- **Full Drag & Drop**: Drop any image (PNG, JPEG, WebP, HEIC, TIFF, GIF) directly onto the canvas.
- **Procedural Demo Generator**: Includes built-in high-detail test scenes (*Synthwave Sunset* and *Color Calibration Chart*) so you can test all modes immediately.

---

## 🎨 Modes & Capabilities

### 1. Pixelated View
- **Pixel Size Slider**: From 1px (original) up to 80+ px blocks.
- **Quick Presets**: 4px, 8px, 16px, 24px, 32px, 48px.
- **Pixel Grid Mesh**: Toggleable retro grid overlay with adjustable line opacity.
- **Color Quantization**: Posterize from 2 to 32 color levels per channel for authentic 8-bit/16-bit looks.

### 2. RGB Modes & Channels
- **Channel Isolation**: Full RGB, Red Only, Green Only, Blue Only, Cyan (G+B), Magenta (R+B), Yellow (R+G).
- **Monochrome Channel Views**: Red (B&W), Green (B&W), Blue (B&W).
- **3D Chromatic Aberration**: Horizontal and vertical channel shifting for 3D anaglyph or glitch art aesthetics.
- **Channel Gains**: Independent fine-tuning of Red, Green, and Blue multipliers (0.0x - 2.0x).

### 3. Black & White / Dithering
- **Grayscale**: High-fidelity perceptual luminance.
- **1-Bit Threshold**: High-contrast binary with adjustable threshold cutoff (0% - 100%).
- **Bayer 4x4 Ordered Dithering**: Authentic 1-bit Macintosh 1984 / compact retro print halftone.
- **Bayer 8x8 Ordered Dithering**: Classic smooth ordered gradient dithering.
- **Floyd-Steinberg Dithering**: Multi-core error diffusion algorithm.
- **Inverted B&W**: Photographic negative monochrome.

### 4. Retro Color Palettes
- **Nintendo Game Boy (1989)**: 4 shades of retro olive-green.
- **IBM CGA Mode 1 (1981)**: Black, Cyan, Magenta, White.
- **Cyberpunk Neon**: Midnight Navy, Hot Pink, Electric Cyan, Neon Yellow.
- **Amber CRT Terminal**: Monochrome amber phosphor.
- **Matrix Green Phosphor**: Matrix terminal green palette.
- **Commodore 64**: Classic 8-color microcomputer palette.
- **Thermal Heatmap**: Infrared false-color spectrum.

### 5. CRT Arcade Monitor
- Hardware-accelerated horizontal scanline rasterization with density and intensity controls.

---

## 📥 Download & Installation

### Option 1: Download from GitHub Releases (Recommended)
1. Go to the [**Releases**](https://github.com/mrh-jishan/PixelForge/releases) page.
2. Download **`PixelForge-macOS.dmg`** (or `PixelForge-macOS.zip`).
3. Open the disk image and drag **PixelForge** into your **Applications** folder.
4. **First Launch (macOS Gatekeeper)**:
   - Because PixelForge is open-source and built on GitHub Actions without an expensive Apple Developer ID certificate, right-click (or Control-click) `PixelForge.app` in Applications and select **Open** -> **Open**.
   - Or run once in Terminal:
     ```bash
     xattr -cr /Applications/PixelForge.app
     ```

### Option 2: Build from Source
```bash
git clone https://github.com/mrh-jishan/PixelForge.git
cd PixelForge
./build.sh --package
open PixelForge.app
```

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `⌘O` | Open Image File |
| `⌘S` | Export Processed Image (PNG / JPEG) |
| `⌘C` | Copy Processed Image to Clipboard |
| `⌘D` | Toggle Split Compare View |
| `⌘R` | Reset All Filter Adjustments |
| `Space` | Quick Preview Original Image |
| `Pinch / Scroll` | Smooth Zoom (up to 3200%) |
| `Click & Drag` | Pan around zoomed image |
