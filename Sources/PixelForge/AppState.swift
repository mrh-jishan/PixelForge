import Foundation
import CoreGraphics
import AppKit
import UniformTypeIdentifiers
import SwiftUI

public enum AppPreset: String, CaseIterable, Identifiable {
    case original = "Reset / Original"
    case chunky8Bit = "8-Bit Chunky"
    case gameBoy = "Game Boy (1989)"
    case mac1984 = "1-Bit Mac (1984)"
    case cgaRetro = "CGA PC (1981)"
    case cyberpunkAnaglyph = "Cyber 3D Anaglyph"
    case crtArcade = "CRT Arcade Monitor"
    case greenMatrix = "Matrix Phosphor"
    case amberTerminal = "Amber CRT Terminal"
    
    public var id: String { rawValue }
}

@MainActor
public final class AppState: ObservableObject {
    @Published public var originalCGImage: CGImage?
    @Published public var processedCGImage: CGImage?
    
    @Published public var imageTitle: String = "Synthwave Sunset (Sample)"
    @Published public var imageDimensions: CGSize = .zero
    @Published public var effectiveGridSize: (width: Int, height: Int) = (0, 0)
    
    @Published public var filterParams = FilterParams()
    @Published public var isProcessing: Bool = false
    @Published public var processingDurationMs: Double = 0.0
    
    // Viewport transform
    @Published public var zoomScale: CGFloat = 1.0
    @Published public var panOffset: CGSize = .zero
    
    // Comparison
    @Published public var showSplitCompare: Bool = false
    @Published public var splitPosition: CGFloat = 0.5
    @Published public var showOriginalOnly: Bool = false
    
    private var renderTask: Task<Void, Never>?
    
    public init() {
        // Load default procedural demo scene
        loadSampleSynthwave()
    }
    
    public func loadSampleSynthwave() {
        if let img = SampleImageGenerator.generateSynthwave() {
            loadImage(cgImage: img, title: "Synthwave Sunset (Sample)")
        }
    }
    
    public func loadSampleColorBars() {
        if let img = SampleImageGenerator.generateColorBars() {
            loadImage(cgImage: img, title: "Color Bars & Test Chart (Sample)")
        }
    }
    
    public func loadImage(cgImage: CGImage, title: String) {
        self.originalCGImage = cgImage
        self.imageTitle = title
        self.imageDimensions = CGSize(width: cgImage.width, height: cgImage.height)
        self.zoomScale = 1.0
        self.panOffset = .zero
        scheduleProcess()
    }
    
    public func loadImage(from url: URL) {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return
        }
        loadImage(cgImage: cgImage, title: url.lastPathComponent)
    }
    
    public func scheduleProcess() {
        renderTask?.cancel()
        
        guard let inputImage = originalCGImage else {
            self.processedCGImage = nil
            return
        }
        
        let params = self.filterParams
        self.isProcessing = true
        
        renderTask = Task.detached(priority: .userInitiated) {
            let result = ImageProcessor.shared.process(cgImage: inputImage, params: params)
            
            if !Task.isCancelled {
                await MainActor.run {
                    if let result = result {
                        self.processedCGImage = result.image
                        self.processingDurationMs = result.durationMs
                        self.effectiveGridSize = (result.effectiveGridWidth, result.effectiveGridHeight)
                    }
                    self.isProcessing = false
                }
            }
        }
    }
    
    public func applyPreset(_ preset: AppPreset) {
        var p = FilterParams()
        switch preset {
        case .original:
            p.pixelSize = 1.0
            p.category = .pixelate
            p.activePalette = nil
            
        case .chunky8Bit:
            p.category = .pixelate
            p.pixelSize = 16.0
            p.posterizeLevels = 6.0
            p.showPixelGrid = true
            p.gridOpacity = 0.25
            p.activePalette = nil
            
        case .gameBoy:
            p.category = .pixelate
            p.retroPalette = .gameBoy
            p.activePalette = .gameBoy
            p.pixelSize = 12.0
            p.showPixelGrid = true
            p.gridOpacity = 0.35
            
        case .mac1984:
            p.category = .blackAndWhite
            p.bwMode = .bayer4x4
            p.pixelSize = 8.0
            p.showPixelGrid = false
            p.activePalette = nil
            
        case .cgaRetro:
            p.category = .pixelate
            p.retroPalette = .cgaMode1
            p.activePalette = .cgaMode1
            p.pixelSize = 10.0
            p.showPixelGrid = true
            p.gridOpacity = 0.2
            
        case .cyberpunkAnaglyph:
            p.category = .rgbChannels
            p.pixelSize = 8.0
            p.chromaticShiftX = 14.0
            p.chromaticShiftY = 2.0
            p.saturation = 1.4
            p.activePalette = nil
            
        case .crtArcade:
            p.category = .crtArcade
            p.pixelSize = 6.0
            p.crtIntensity = 0.55
            p.crtDensity = 2.0
            p.contrast = 1.2
            p.activePalette = nil
            
        case .greenMatrix:
            p.category = .pixelate
            p.retroPalette = .matrixGreen
            p.activePalette = .matrixGreen
            p.pixelSize = 8.0
            p.showPixelGrid = true
            p.gridOpacity = 0.4
            
        case .amberTerminal:
            p.category = .pixelate
            p.retroPalette = .amberCRT
            p.activePalette = .amberCRT
            p.pixelSize = 10.0
            p.showPixelGrid = true
            p.gridOpacity = 0.3
        }
        
        self.filterParams = p
        scheduleProcess()
    }
    
    public func resetFilters() {
        self.filterParams = FilterParams()
        scheduleProcess()
    }
    
    public func fitToScreen(viewportSize: CGSize) {
        guard imageDimensions.width > 0, imageDimensions.height > 0,
              viewportSize.width > 0, viewportSize.height > 0 else { return }
        
        let scaleX = (viewportSize.width - 60) / imageDimensions.width
        let scaleY = (viewportSize.height - 60) / imageDimensions.height
        let bestScale = min(scaleX, scaleY)
        
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            self.zoomScale = max(0.05, min(bestScale, 4.0))
            self.panOffset = .zero
        }
    }
    
    public func setActualSize() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
            self.zoomScale = 1.0
            self.panOffset = .zero
        }
    }
    
    public func zoomIn() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
            self.zoomScale = min(self.zoomScale * 1.35, 32.0)
        }
    }
    
    public func zoomOut() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.85)) {
            self.zoomScale = max(self.zoomScale / 1.35, 0.05)
        }
    }
    
    public func copyToClipboard() {
        guard let output = (showOriginalOnly ? originalCGImage : processedCGImage) ?? originalCGImage else { return }
        let rep = NSBitmapImageRep(cgImage: output)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let pngData = rep.representation(using: .png, properties: [:]) {
            pasteboard.setData(pngData, forType: .png)
        }
    }
    
    public func openImagePanel() {
        let panel = NSOpenPanel()
        panel.title = "Select an Image to Pixelate"
        panel.allowedContentTypes = [.image, .png, .jpeg, .tiff, .gif, .webP, .heic]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }
    
    public func saveImagePanel() {
        guard let output = processedCGImage else { return }
        let panel = NSSavePanel()
        panel.title = "Save Pixelated Image"
        let baseName = imageTitle.replacingOccurrences(of: "\\.[^.]+$", with: "", options: .regularExpression)
        panel.nameFieldStringValue = "\(baseName)_pixelated.png"
        panel.allowedContentTypes = [.png, .jpeg]
        
        if panel.runModal() == .OK, let url = panel.url {
            let isJPEG = url.pathExtension.lowercased() == "jpg" || url.pathExtension.lowercased() == "jpeg"
            let rep = NSBitmapImageRep(cgImage: output)
            let fileType: NSBitmapImageRep.FileType = isJPEG ? .jpeg : .png
            if let data = rep.representation(using: fileType, properties: [:]) {
                try? data.write(to: url)
            }
        }
    }
}
