import Foundation
import CoreGraphics
import AppKit

public struct SampleImageGenerator {
    
    public static func generateSynthwave(width: Int = 1280, height: Int = 800) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        let w = CGFloat(width)
        let h = CGFloat(height)
        
        // 1. Sky Gradient (Deep Indigo to Neon Magenta/Orange)
        let skyColors = [
            NSColor(red: 0.05, green: 0.02, blue: 0.15, alpha: 1.0).cgColor,
            NSColor(red: 0.25, green: 0.05, blue: 0.35, alpha: 1.0).cgColor,
            NSColor(red: 0.85, green: 0.15, blue: 0.50, alpha: 1.0).cgColor,
            NSColor(red: 1.00, green: 0.55, blue: 0.20, alpha: 1.0).cgColor
        ] as CFArray
        let skyLocs: [CGFloat] = [0.0, 0.4, 0.75, 1.0]
        if let skyGrad = CGGradient(colorsSpace: colorSpace, colors: skyColors, locations: skyLocs) {
            ctx.drawLinearGradient(skyGrad, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: h * 0.4), options: [])
        }
        
        // 2. Stars
        ctx.setFillColor(NSColor.white.cgColor)
        var rng = 1234567
        for _ in 0..<120 {
            rng = (rng &* 1103515245 &+ 12345) & 0x7fffffff
            let sx = CGFloat(rng % Int(w))
            rng = (rng &* 1103515245 &+ 12345) & 0x7fffffff
            let sy = h * 0.45 + CGFloat(rng % Int(h * 0.52))
            let sSize = CGFloat((rng % 3) + 1)
            ctx.fillEllipse(in: CGRect(x: sx, y: sy, width: sSize, height: sSize))
        }
        
        // 3. Synthwave Sun
        let sunRadius: CGFloat = h * 0.26
        let sunCenter = CGPoint(x: w * 0.5, y: h * 0.46)
        let sunRect = CGRect(x: sunCenter.x - sunRadius, y: sunCenter.y - sunRadius, width: sunRadius * 2, height: sunRadius * 2)
        
        ctx.saveGState()
        ctx.addEllipse(in: sunRect)
        ctx.clip()
        
        let sunColors = [
            NSColor(red: 1.0, green: 0.95, blue: 0.2, alpha: 1.0).cgColor,
            NSColor(red: 1.0, green: 0.20, blue: 0.4, alpha: 1.0).cgColor
        ] as CFArray
        if let sunGrad = CGGradient(colorsSpace: colorSpace, colors: sunColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(sunGrad, start: CGPoint(x: sunCenter.x, y: sunCenter.y + sunRadius), end: CGPoint(x: sunCenter.x, y: sunCenter.y - sunRadius), options: [])
        }
        
        // Sun horizontal black scanline cuts
        ctx.setFillColor(NSColor(red: 0.05, green: 0.02, blue: 0.15, alpha: 1.0).cgColor)
        var slitY = sunCenter.y - sunRadius + 15
        var slitHeight: CGFloat = 3.0
        while slitY < sunCenter.y + 10 {
            ctx.fill(CGRect(x: sunCenter.x - sunRadius - 10, y: slitY, width: sunRadius * 2 + 20, height: slitHeight))
            slitY += slitHeight + 7.0
            slitHeight += 1.8
        }
        ctx.restoreGState()
        
        // 4. Distant Mountain Silhouettes
        ctx.setFillColor(NSColor(red: 0.10, green: 0.03, blue: 0.20, alpha: 1.0).cgColor)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: 0, y: h * 0.38))
        let mountainPoints: [(CGFloat, CGFloat)] = [
            (0.12, 0.47), (0.22, 0.40), (0.35, 0.52), (0.45, 0.42),
            (0.55, 0.49), (0.68, 0.41), (0.80, 0.50), (0.92, 0.43), (1.0, 0.38)
        ]
        for pt in mountainPoints {
            ctx.addLine(to: CGPoint(x: w * pt.0, y: h * pt.1))
        }
        ctx.addLine(to: CGPoint(x: w, y: 0))
        ctx.addLine(to: CGPoint(x: 0, y: 0))
        ctx.closePath()
        ctx.fillPath()
        
        // 5. Floor Grid
        let floorColors = [
            NSColor(red: 0.02, green: 0.01, blue: 0.08, alpha: 1.0).cgColor,
            NSColor(red: 0.15, green: 0.02, blue: 0.25, alpha: 1.0).cgColor
        ] as CFArray
        if let floorGrad = CGGradient(colorsSpace: colorSpace, colors: floorColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(floorGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: h * 0.38), options: [])
        }
        
        // Perspective Grid Lines
        ctx.setStrokeColor(NSColor(red: 0.0, green: 0.95, blue: 0.95, alpha: 0.75).cgColor)
        ctx.setLineWidth(1.8)
        
        let vanishingPoint = CGPoint(x: w * 0.5, y: h * 0.38)
        
        // Radial lines
        let numRays = 24
        for i in 0...numRays {
            let t = CGFloat(i) / CGFloat(numRays)
            let bottomX = -w * 0.2 + t * (w * 1.4)
            ctx.beginPath()
            ctx.move(to: vanishingPoint)
            ctx.addLine(to: CGPoint(x: bottomX, y: 0))
            ctx.strokePath()
        }
        
        // Horizontal lines with exponential perspective spacing
        var gy: CGFloat = 0
        var spacing: CGFloat = 3.0
        while gy < h * 0.38 {
            ctx.beginPath()
            ctx.move(to: CGPoint(x: 0, y: gy))
            ctx.addLine(to: CGPoint(x: w, y: gy))
            ctx.strokePath()
            gy += spacing
            spacing *= 1.18
        }
        
        return ctx.makeImage()
    }
    
    public static func generateColorBars(width: Int = 1280, height: Int = 800) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        let w = CGFloat(width)
        let h = CGFloat(height)
        
        // SMPTE standard colors
        let smpteColors: [NSColor] = [
            NSColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0), // 75% Gray
            NSColor(red: 0.75, green: 0.75, blue: 0.00, alpha: 1.0), // Yellow
            NSColor(red: 0.00, green: 0.75, blue: 0.75, alpha: 1.0), // Cyan
            NSColor(red: 0.00, green: 0.75, blue: 0.00, alpha: 1.0), // Green
            NSColor(red: 0.75, green: 0.00, blue: 0.75, alpha: 1.0), // Magenta
            NSColor(red: 0.75, green: 0.00, blue: 0.00, alpha: 1.0), // Red
            NSColor(red: 0.00, green: 0.00, blue: 0.75, alpha: 1.0)  // Blue
        ]
        
        let barW = w / CGFloat(smpteColors.count)
        for (i, c) in smpteColors.enumerated() {
            ctx.setFillColor(c.cgColor)
            ctx.fill(CGRect(x: CGFloat(i) * barW, y: h * 0.35, width: barW, height: h * 0.65))
        }
        
        // Gradient ramps at the bottom
        for x in 0..<Int(w) {
            let t = CGFloat(x) / w
            // Grayscale ramp
            ctx.setFillColor(NSColor(white: t, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: CGFloat(x), y: h * 0.20, width: 1.0, height: h * 0.15))
            
            // RGB Rainbow ramp
            let hue = t
            let rainbowColor = NSColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            ctx.setFillColor(rainbowColor.cgColor)
            ctx.fill(CGRect(x: CGFloat(x), y: 0, width: 1.0, height: h * 0.20))
        }
        
        return ctx.makeImage()
    }
}
