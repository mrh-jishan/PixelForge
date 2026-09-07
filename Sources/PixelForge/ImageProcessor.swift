import Foundation
import CoreImage
import CoreGraphics
import Metal

public struct ProcessResult {
    public let image: CGImage
    public let durationMs: Double
    public let effectiveGridWidth: Int
    public let effectiveGridHeight: Int
}

public final class ImageProcessor {
    public static let shared = ImageProcessor()
    
    private let ciContext: CIContext
    private let metalDevice: MTLDevice?
    
    public init() {
        if let device = MTLCreateSystemDefaultDevice() {
            self.metalDevice = device
            self.ciContext = CIContext(mtlDevice: device, options: [
                .useSoftwareRenderer: false,
                .priorityRequestLow: false
            ])
        } else {
            self.metalDevice = nil
            self.ciContext = CIContext(options: nil)
        }
    }
    
    public func process(cgImage: CGImage, params: FilterParams) -> ProcessResult? {
        let startTime = DispatchTime.now()
        let width = cgImage.width
        let height = cgImage.height
        let extent = CGRect(x: 0, y: 0, width: width, height: height)
        
        let effectiveBlockSize = max(1.0, params.pixelSize)
        let gridW = max(1, Int(ceil(Double(width) / effectiveBlockSize)))
        let gridH = max(1, Int(ceil(Double(height) / effectiveBlockSize)))
        
        var currentCI = CIImage(cgImage: cgImage)
        
        // 1. Color Pre-adjustments (Brightness, Contrast, Saturation)
        if params.brightness != 0.0 || params.contrast != 1.0 || params.saturation != 1.0 {
            if let colorFilter = CIFilter(name: "CIColorControls") {
                colorFilter.setValue(currentCI, forKey: kCIInputImageKey)
                colorFilter.setValue(params.brightness, forKey: kCIInputBrightnessKey)
                colorFilter.setValue(params.contrast, forKey: kCIInputContrastKey)
                colorFilter.setValue(params.saturation, forKey: kCIInputSaturationKey)
                if let out = colorFilter.outputImage {
                    currentCI = out
                }
            }
        }
        
        // 2. Pixelation (Metal GPU accelerated)
        if params.pixelSize > 1.0 {
            if let pixellate = CIFilter(name: "CIPixellate") {
                pixellate.setValue(currentCI, forKey: kCIInputImageKey)
                pixellate.setValue(params.pixelSize, forKey: kCIInputScaleKey)
                pixellate.setValue(CIVector(x: 0, y: 0), forKey: kCIInputCenterKey)
                if let out = pixellate.outputImage {
                    currentCI = out.cropped(to: extent)
                }
            }
        }
        
        // 3. Category Specific Processing
        var intermediateCG: CGImage?
        
        switch params.category {
        case .pixelate:
            if params.posterizeLevels >= 2.0 {
                if let posterize = CIFilter(name: "CIColorPosterize") {
                    posterize.setValue(currentCI, forKey: kCIInputImageKey)
                    posterize.setValue(params.posterizeLevels, forKey: "inputLevels")
                    if let out = posterize.outputImage {
                        currentCI = out.cropped(to: extent)
                    }
                }
            }
            intermediateCG = ciContext.createCGImage(currentCI, from: extent)
            
        case .rgbChannels:
            // Chromatic shift or channel matrix
            if abs(params.chromaticShiftX) > 0.01 || abs(params.chromaticShiftY) > 0.01 {
                currentCI = applyChromaticShift(image: currentCI, extent: extent, dx: params.chromaticShiftX, dy: params.chromaticShiftY)
            }
            
            currentCI = applyRGBChannelFilter(image: currentCI, mode: params.rgbMode, rGain: params.rGain, gGain: params.gGain, bGain: params.bGain)
            intermediateCG = ciContext.createCGImage(currentCI, from: extent)
            
        case .blackAndWhite:
            switch params.bwMode {
            case .grayscale:
                if let bwFilter = CIFilter(name: "CIColorControls") {
                    bwFilter.setValue(currentCI, forKey: kCIInputImageKey)
                    bwFilter.setValue(0.0, forKey: kCIInputSaturationKey)
                    if let out = bwFilter.outputImage {
                        currentCI = out.cropped(to: extent)
                    }
                }
                intermediateCG = ciContext.createCGImage(currentCI, from: extent)
                
            case .threshold:
                if let baseCG = ciContext.createCGImage(currentCI, from: extent) {
                    intermediateCG = DitheringAndPalettes.applyThreshold(to: baseCG, threshold: params.threshold)
                }
                
            case .bayer4x4:
                if let baseCG = ciContext.createCGImage(currentCI, from: extent) {
                    intermediateCG = DitheringAndPalettes.applyBayerDither(to: baseCG, matrixSize: 4)
                }
                
            case .bayer8x8:
                if let baseCG = ciContext.createCGImage(currentCI, from: extent) {
                    intermediateCG = DitheringAndPalettes.applyBayerDither(to: baseCG, matrixSize: 8)
                }
                
            case .floydSteinberg:
                if let baseCG = ciContext.createCGImage(currentCI, from: extent) {
                    intermediateCG = DitheringAndPalettes.applyFloydSteinberg(to: baseCG)
                }
                
            case .inverted:
                if let bwFilter = CIFilter(name: "CIColorControls") {
                    bwFilter.setValue(currentCI, forKey: kCIInputImageKey)
                    bwFilter.setValue(0.0, forKey: kCIInputSaturationKey)
                    if let out = bwFilter.outputImage,
                       let invert = CIFilter(name: "CIColorInvert") {
                        invert.setValue(out, forKey: kCIInputImageKey)
                        if let invOut = invert.outputImage {
                            currentCI = invOut.cropped(to: extent)
                        }
                    }
                }
                intermediateCG = ciContext.createCGImage(currentCI, from: extent)
            }
            
        case .retroPalette:
            if let baseCG = ciContext.createCGImage(currentCI, from: extent) {
                intermediateCG = DitheringAndPalettes.applyPalette(to: baseCG, palette: params.retroPalette)
            }
            
        case .crtArcade:
            if let baseCG = ciContext.createCGImage(currentCI, from: extent) {
                intermediateCG = DitheringAndPalettes.applyCRTScanlines(to: baseCG, intensity: params.crtIntensity, density: params.crtDensity)
            }
        }
        
        guard var finalCG = intermediateCG else { return nil }
        
        // 4. Overlays: Pixel Grid Overlay
        if params.showPixelGrid && params.pixelSize > 2.0 {
            if let withGrid = DitheringAndPalettes.applyPixelGridOverlay(to: finalCG, blockSize: Int(params.pixelSize), opacity: params.gridOpacity) {
                finalCG = withGrid
            }
        }
        
        let endTime = DispatchTime.now()
        let ms = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0
        
        return ProcessResult(image: finalCG, durationMs: ms, effectiveGridWidth: gridW, effectiveGridHeight: gridH)
    }
    
    private func applyRGBChannelFilter(image: CIImage, mode: RGBChannelMode, rGain: Double, gGain: Double, bGain: Double) -> CIImage {
        guard let matrix = CIFilter(name: "CIColorMatrix") else { return image }
        matrix.setValue(image, forKey: kCIInputImageKey)
        
        let r = CGFloat(rGain)
        let g = CGFloat(gGain)
        let b = CGFloat(bGain)
        
        switch mode {
        case .all:
            matrix.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")
            
        case .redOnly:
            matrix.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
            
        case .greenOnly:
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
            
        case .blueOnly:
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")
            
        case .redMonochrome:
            matrix.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputBVector")
            
        case .greenMonochrome:
            matrix.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputBVector")
            
        case .blueMonochrome:
            matrix.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")
            
        case .cyan:
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")
            
        case .magenta:
            matrix.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")
            
        case .yellow:
            matrix.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
            matrix.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
            matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        }
        
        matrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        return matrix.outputImage ?? image
    }
    
    private func applyChromaticShift(image: CIImage, extent: CGRect, dx: Double, dy: Double) -> CIImage {
        // Red channel
        guard let redMatrix = CIFilter(name: "CIColorMatrix") else { return image }
        redMatrix.setValue(image, forKey: kCIInputImageKey)
        redMatrix.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        redMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        redMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        redMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        guard let redOnly = redMatrix.outputImage else { return image }
        
        // Cyan channel (G + B)
        guard let cyanMatrix = CIFilter(name: "CIColorMatrix") else { return image }
        cyanMatrix.setValue(image, forKey: kCIInputImageKey)
        cyanMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        cyanMatrix.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        cyanMatrix.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        cyanMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        guard let cyanOnly = cyanMatrix.outputImage else { return image }
        
        // Translate Red by (+dx, +dy) and Cyan by (-dx, -dy)
        let redShifted = redOnly.transformed(by: CGAffineTransform(translationX: CGFloat(dx), y: CGFloat(dy)))
        let cyanShifted = cyanOnly.transformed(by: CGAffineTransform(translationX: CGFloat(-dx), y: CGFloat(-dy)))
        
        // Screen blend or additive blend
        guard let blend = CIFilter(name: "CIScreenBlendMode") else { return image }
        blend.setValue(redShifted, forKey: kCIInputImageKey)
        blend.setValue(cyanShifted, forKey: kCIInputBackgroundImageKey)
        
        return blend.outputImage?.cropped(to: extent) ?? image
    }
}
