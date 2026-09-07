import Foundation
import CoreGraphics

public enum FilterCategory: String, CaseIterable, Identifiable {
    case pixelate = "Pixelate"
    case rgbChannels = "RGB Channels"
    case blackAndWhite = "Black & White"
    case retroPalette = "Retro Palettes"
    case crtArcade = "CRT Arcade"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .pixelate: return "square.grid.3x3.fill"
        case .rgbChannels: return "paintpalette.fill"
        case .blackAndWhite: return "circle.lefthalf.filled"
        case .retroPalette: return "gamecontroller.fill"
        case .crtArcade: return "tv.fill"
        }
    }
}

public enum PixelSampleMode: String, CaseIterable, Identifiable {
    case average = "Area Average"
    case point = "Point Sample"
    
    public var id: String { rawValue }
}

public enum RGBChannelMode: String, CaseIterable, Identifiable {
    case all = "Full RGB"
    case redOnly = "Red Only"
    case greenOnly = "Green Only"
    case blueOnly = "Blue Only"
    case redMonochrome = "Red (B&W)"
    case greenMonochrome = "Green (B&W)"
    case blueMonochrome = "Blue (B&W)"
    case cyan = "Cyan (G+B)"
    case magenta = "Magenta (R+B)"
    case yellow = "Yellow (R+G)"
    
    public var id: String { rawValue }
}

public enum BWMode: String, CaseIterable, Identifiable {
    case grayscale = "Grayscale"
    case threshold = "1-Bit Threshold"
    case bayer4x4 = "Bayer 4x4 Dither"
    case bayer8x8 = "Bayer 8x8 Dither"
    case floydSteinberg = "Floyd-Steinberg"
    case inverted = "Inverted B&W"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .grayscale: return "Smooth perceptual luminance"
        case .threshold: return "High-contrast binary black & white"
        case .bayer4x4: return "Retro 1-bit ordered dither (compact)"
        case .bayer8x8: return "Classic 1-bit ordered dither (smooth)"
        case .floydSteinberg: return "Error diffusion halftone dithering"
        case .inverted: return "Monochrome photographic negative"
        }
    }
}

public enum RetroPalette: String, CaseIterable, Identifiable {
    case gameBoy = "Game Boy (1989)"
    case cgaMode1 = "CGA Mode 1 (1981)"
    case cyberpunk = "Cyberpunk Neon"
    case amberCRT = "Amber CRT Terminal"
    case matrixGreen = "Green Phosphor"
    case commodore64 = "Commodore 64"
    case thermalHeatmap = "Thermal Heatmap"
    
    public var id: String { rawValue }
    
    public var colors: [UInt32] {
        // Colors formatted as 0xRRGGBB
        switch self {
        case .gameBoy:
            return [0x0f380f, 0x306230, 0x8bac0f, 0x9bbc0f]
        case .cgaMode1:
            return [0x000000, 0x55ffff, 0xff55ff, 0xffffff]
        case .cyberpunk:
            return [0x0d1b2a, 0x1b263b, 0xff007f, 0x00f5d4, 0xfee440]
        case .amberCRT:
            return [0x000000, 0x4a2800, 0x995200, 0xff9500, 0xffd000]
        case .matrixGreen:
            return [0x000000, 0x003300, 0x008000, 0x00ff66, 0x80ffaa]
        case .commodore64:
            return [0x000000, 0xffffff, 0x880000, 0xaaffee, 0xcc44cc, 0x00cc55, 0x0000aa, 0xeeee77]
        case .thermalHeatmap:
            return [0x000033, 0x0000ff, 0x00ffff, 0x00ff00, 0xffff00, 0xff0000, 0xffffff]
        }
    }
}

public struct FilterParams: Equatable {
    public var category: FilterCategory = .pixelate
    
    // Pixelation Parameters
    public var pixelSize: Double = 16.0         // 1 to 128
    public var sampleMode: PixelSampleMode = .average
    public var showPixelGrid: Bool = false
    public var gridOpacity: Double = 0.25
    public var posterizeLevels: Double = 0       // 0 = disabled, 2...32
    
    // RGB Channel Parameters
    public var rgbMode: RGBChannelMode = .all
    public var rGain: Double = 1.0              // 0 to 2
    public var gGain: Double = 1.0              // 0 to 2
    public var bGain: Double = 1.0              // 0 to 2
    public var chromaticShiftX: Double = 0.0    // -30 to 30
    public var chromaticShiftY: Double = 0.0    // -30 to 30
    
    // Black & White Parameters
    public var bwMode: BWMode = .grayscale
    public var threshold: Double = 0.5          // 0 to 1
    
    // Retro Palettes
    public var retroPalette: RetroPalette = .gameBoy
    
    // CRT Arcade Parameters
    public var crtScanlines: Bool = false
    public var crtIntensity: Double = 0.4       // 0 to 1
    public var crtDensity: Double = 2.0         // 1 to 4
    public var crtVignette: Bool = false
    
    // Global Color Adjustments
    public var brightness: Double = 0.0         // -0.5 to 0.5
    public var contrast: Double = 1.0           // 0.5 to 2.0
    public var saturation: Double = 1.0         // 0.0 to 2.0
    
    public init() {}
}
