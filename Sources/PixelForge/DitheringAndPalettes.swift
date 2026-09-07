import Foundation
import CoreGraphics

public final class DitheringAndPalettes {
    
    // Bayer 4x4 threshold matrix (scaled 0...255)
    private static let bayer4x4: [UInt8] = [
          0, 128,  32, 160,
        192,  64, 224,  96,
         48, 176,  16, 144,
        240, 112, 208,  80
    ]
    
    // Bayer 8x8 threshold matrix (scaled 0...255)
    private static let bayer8x8: [UInt8] = [
          0, 128,  32, 160,   8, 136,  40, 168,
        192,  64, 224,  96, 200,  72, 232, 104,
         48, 176,  16, 144,  56, 184,  24, 152,
        240, 112, 208,  80, 248, 120, 216,  88,
         12, 140,  44, 172,   4, 132,  36, 164,
        204,  76, 236, 108, 196,  68, 228, 100,
         60, 188,  28, 156,  52, 180,  20, 148,
        252, 124, 220,  92, 244, 116, 212,  84
    ]
    
    public static func applyBayerDither(to input: CGImage, matrixSize: Int) -> CGImage? {
        let width = input.width
        let height = input.height
        
        guard let context = createRGBAContext(width: width, height: height) else { return nil }
        context.draw(input, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return nil }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let is8x8 = (matrixSize == 8)
        let matrix = is8x8 ? bayer8x8 : bayer4x4
        let mask: Int = is8x8 ? 7 : 3
        let shift: Int = is8x8 ? 3 : 2
        
        DispatchQueue.concurrentPerform(iterations: height) { y in
            let rowOffset = y * width * 4
            let matrixRow = (y & mask) << shift
            for x in 0..<width {
                let idx = rowOffset + (x << 2)
                let r = UInt32(ptr[idx])
                let g = UInt32(ptr[idx + 1])
                let b = UInt32(ptr[idx + 2])
                let lum = UInt8((77 * r + 150 * g + 29 * b) >> 8)
                let threshold = matrix[matrixRow | (x & mask)]
                let val: UInt8 = lum > threshold ? 255 : 0
                ptr[idx] = val
                ptr[idx + 1] = val
                ptr[idx + 2] = val
            }
        }
        
        return context.makeImage()
    }
    
    public static func applyThreshold(to input: CGImage, threshold: Double) -> CGImage? {
        let width = input.width
        let height = input.height
        let thresholdByte = UInt8(clamping: Int(threshold * 255.0))
        
        guard let context = createRGBAContext(width: width, height: height) else { return nil }
        context.draw(input, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return nil }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        DispatchQueue.concurrentPerform(iterations: height) { y in
            let rowOffset = y * width * 4
            for x in 0..<width {
                let idx = rowOffset + (x << 2)
                let r = UInt32(ptr[idx])
                let g = UInt32(ptr[idx + 1])
                let b = UInt32(ptr[idx + 2])
                let lum = UInt8((77 * r + 150 * g + 29 * b) >> 8)
                let val: UInt8 = lum >= thresholdByte ? 255 : 0
                ptr[idx] = val
                ptr[idx + 1] = val
                ptr[idx + 2] = val
            }
        }
        
        return context.makeImage()
    }
    
    public static func applyFloydSteinberg(to input: CGImage) -> CGImage? {
        let width = input.width
        let height = input.height
        
        guard let context = createRGBAContext(width: width, height: height) else { return nil }
        context.draw(input, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return nil }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        // Extract 16-bit signed grayscale array for accurate error diffusion
        var gray = [Int16](repeating: 0, count: width * height)
        for y in 0..<height {
            let rowOffset = y * width * 4
            let grayRow = y * width
            for x in 0..<width {
                let idx = rowOffset + (x << 2)
                let r = Int32(ptr[idx])
                let g = Int32(ptr[idx + 1])
                let b = Int32(ptr[idx + 2])
                gray[grayRow + x] = Int16((77 * r + 150 * g + 29 * b) >> 8)
            }
        }
        
        for y in 0..<height {
            let rowStart = y * width
            let nextRowStart = (y + 1) * width
            let isNotLastRow = (y + 1 < height)
            
            for x in 0..<width {
                let currentPos = rowStart + x
                let oldVal = Int32(gray[currentPos])
                let clamped = max(0, min(255, oldVal))
                let newVal: Int32 = clamped > 127 ? 255 : 0
                let err = clamped - newVal
                
                // Diffuse error
                if x + 1 < width {
                    gray[currentPos + 1] += Int16((err * 7) / 16)
                }
                if isNotLastRow {
                    if x > 0 {
                        gray[nextRowStart + x - 1] += Int16((err * 3) / 16)
                    }
                    gray[nextRowStart + x] += Int16((err * 5) / 16)
                    if x + 1 < width {
                        gray[nextRowStart + x + 1] += Int16((err * 1) / 16)
                    }
                }
                
                let outByte = UInt8(newVal)
                let idx = (rowStart + x) << 2
                ptr[idx] = outByte
                ptr[idx + 1] = outByte
                ptr[idx + 2] = outByte
            }
        }
        
        return context.makeImage()
    }
    
    public static func applyPalette(to input: CGImage, palette: RetroPalette) -> CGImage? {
        let width = input.width
        let height = input.height
        let rawColors = palette.colors
        
        // Decompose palette into R, G, B components
        struct RGB { let r: Int32; let g: Int32; let b: Int32 }
        let palRGB: [RGB] = rawColors.map { c in
            RGB(r: Int32((c >> 16) & 0xFF),
                g: Int32((c >> 8) & 0xFF),
                b: Int32(c & 0xFF))
        }
        
        guard let context = createRGBAContext(width: width, height: height) else { return nil }
        context.draw(input, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return nil }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        
        DispatchQueue.concurrentPerform(iterations: height) { y in
            let rowOffset = y * width * 4
            for x in 0..<width {
                let idx = rowOffset + (x << 2)
                let pr = Int32(ptr[idx])
                let pg = Int32(ptr[idx + 1])
                let pb = Int32(ptr[idx + 2])
                
                var bestDist = Int32.max
                var bestRGB = palRGB[0]
                
                for c in palRGB {
                    let dr = pr - c.r
                    let dg = pg - c.g
                    let db = pb - c.b
                    // Perceptual weighted color distance
                    let dist = 2 * dr * dr + 4 * dg * dg + 3 * db * db
                    if dist < bestDist {
                        bestDist = dist
                        bestRGB = c
                    }
                }
                
                ptr[idx] = UInt8(bestRGB.r)
                ptr[idx + 1] = UInt8(bestRGB.g)
                ptr[idx + 2] = UInt8(bestRGB.b)
            }
        }
        
        return context.makeImage()
    }
    
    public static func applyPixelGridOverlay(to input: CGImage, blockSize: Int, opacity: Double) -> CGImage? {
        guard blockSize > 2 else { return input }
        let width = input.width
        let height = input.height
        
        guard let context = createRGBAContext(width: width, height: height) else { return input }
        context.draw(input, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return input }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let alpha = max(0.0, min(1.0, opacity))
        let factor = 1.0 - (alpha * 0.7) // Darken factor
        let factorInt = Int32(factor * 256.0)
        
        DispatchQueue.concurrentPerform(iterations: height) { y in
            let isYGrid = (y % blockSize == 0)
            let rowOffset = y * width * 4
            
            for x in 0..<width {
                let isXGrid = (x % blockSize == 0)
                if isXGrid || isYGrid {
                    let idx = rowOffset + (x << 2)
                    ptr[idx] = UInt8((Int32(ptr[idx]) * factorInt) >> 8)
                    ptr[idx + 1] = UInt8((Int32(ptr[idx + 1]) * factorInt) >> 8)
                    ptr[idx + 2] = UInt8((Int32(ptr[idx + 2]) * factorInt) >> 8)
                }
            }
        }
        
        return context.makeImage()
    }
    
    public static func applyCRTScanlines(to input: CGImage, intensity: Double, density: Double) -> CGImage? {
        let width = input.width
        let height = input.height
        let step = max(1, Int(density.rounded()))
        
        guard let context = createRGBAContext(width: width, height: height) else { return input }
        context.draw(input, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return input }
        
        let ptr = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let factor = 1.0 - max(0.0, min(1.0, intensity))
        let factorInt = Int32(factor * 256.0)
        
        DispatchQueue.concurrentPerform(iterations: height) { y in
            if (y / step) % 2 == 1 {
                let rowOffset = y * width * 4
                for x in 0..<width {
                    let idx = rowOffset + (x << 2)
                    ptr[idx] = UInt8((Int32(ptr[idx]) * factorInt) >> 8)
                    ptr[idx + 1] = UInt8((Int32(ptr[idx + 1]) * factorInt) >> 8)
                    ptr[idx + 2] = UInt8((Int32(ptr[idx + 2]) * factorInt) >> 8)
                }
            }
        }
        
        return context.makeImage()
    }
    
    private static func createRGBAContext(width: Int, height: Int) -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        return CGContext(data: nil,
                         width: width,
                         height: height,
                         bitsPerComponent: 8,
                         bytesPerRow: width * 4,
                         space: colorSpace,
                         bitmapInfo: bitmapInfo)
    }
}
