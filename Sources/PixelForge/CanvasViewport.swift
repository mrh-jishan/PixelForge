import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct CanvasViewport: View {
    @ObservedObject var state: AppState
    
    @State private var dragStartPan: CGSize = .zero
    @State private var isDraggingSplitter: Bool = false
    @State private var isTargetedForDrop: Bool = false
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background dark checkerboard for transparency / dark studio mode
                CheckerboardBackground()
                    .ignoresSafeArea()
                
                if let original = state.originalCGImage {
                    let imageSize = state.imageDimensions
                    let displayW = imageSize.width * state.zoomScale
                    let displayH = imageSize.height * state.zoomScale
                    
                    // Main image layer with pan & zoom
                    ZStack {
                        if state.showOriginalOnly {
                            // Quick hold original
                            PixelSharpImageView(cgImage: original)
                                .frame(width: displayW, height: displayH)
                        } else if state.showSplitCompare, let processed = state.processedCGImage {
                            // Split Comparison View
                            SplitCompareView(
                                original: original,
                                processed: processed,
                                width: displayW,
                                height: displayH,
                                splitPosition: $state.splitPosition,
                                isDraggingSplitter: $isDraggingSplitter
                            )
                        } else if let processed = state.processedCGImage {
                            // Filtered image
                            PixelSharpImageView(cgImage: processed)
                                .frame(width: displayW, height: displayH)
                        } else {
                            // Fallback to original
                            PixelSharpImageView(cgImage: original)
                                .frame(width: displayW, height: displayH)
                        }
                    }
                    .offset(state.panOffset)
                    .gesture(
                        // Pan gesture
                        DragGesture()
                            .onChanged { value in
                                if !isDraggingSplitter {
                                    state.panOffset = CGSize(
                                        width: dragStartPan.width + value.translation.width,
                                        height: dragStartPan.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                dragStartPan = state.panOffset
                            }
                    )
                    .gesture(
                        // Pinch to zoom
                        MagnificationGesture()
                            .onChanged { scale in
                                let newZoom = state.zoomScale * scale
                                state.zoomScale = max(0.05, min(newZoom, 32.0))
                            }
                    )
                    .onAppear {
                        dragStartPan = state.panOffset
                        // Auto fit on first appearance if image is larger than canvas
                        if state.zoomScale == 1.0 && (imageSize.width > proxy.size.width || imageSize.height > proxy.size.height) {
                            state.fitToScreen(viewportSize: proxy.size)
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.secondary)
                        Text("Drop an image here or open from toolbar")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Load Synthwave Demo") {
                            state.loadSampleSynthwave()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Drop highlight
                if isTargetedForDrop {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor, lineWidth: 4)
                        .background(Color.accentColor.opacity(0.12))
                        .ignoresSafeArea()
                }
                
                // Top HUD / Comparison status badge
                VStack {
                    HStack {
                        if state.showOriginalOnly {
                            Text("HOLDING ORIGINAL")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(6)
                                .foregroundColor(.yellow)
                        }
                        Spacer()
                    }
                    .padding(16)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            state.loadImage(from: url)
                        }
                    }
                }
                return true
            }
        }
    }
}

// Crisp Nearest-Neighbor Image Display
public struct PixelSharpImageView: NSViewRepresentable {
    public let cgImage: CGImage
    
    public func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleAxesIndependently
        view.wantsLayer = true
        view.layer?.magnificationFilter = .nearest
        view.layer?.minificationFilter = .nearest
        return view
    }
    
    public func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        nsView.layer?.magnificationFilter = .nearest
        nsView.layer?.minificationFilter = .nearest
    }
}

// Draggable Split Comparison View
public struct SplitCompareView: View {
    public let original: CGImage
    public let processed: CGImage
    public let width: CGFloat
    public let height: CGFloat
    @Binding public var splitPosition: CGFloat
    @Binding public var isDraggingSplitter: Bool
    
    public var body: some View {
        ZStack {
            // Full Processed Image behind
            PixelSharpImageView(cgImage: processed)
                .frame(width: width, height: height)
            
            // Original Image clipped to the left of the split
            PixelSharpImageView(cgImage: original)
                .frame(width: width, height: height)
                .mask(
                    HStack(spacing: 0) {
                        Rectangle()
                            .frame(width: max(0, width * splitPosition))
                        Spacer(minLength: 0)
                    }
                    .frame(width: width, height: height)
                )
            
            // Split line and handle
            let splitX = -width / 2.0 + (width * splitPosition)
            
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: height)
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 0)
                
                // Draggable Pill
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 8, weight: .bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white))
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
            }
            .offset(x: splitX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDraggingSplitter = true
                        let localX = value.location.x
                        let newPos = max(0.01, min(0.99, localX / width))
                        splitPosition = newPos
                    }
                    .onEnded { _ in
                        isDraggingSplitter = false
                    }
            )
            
            // Badges
            VStack {
                Spacer()
                HStack {
                    Text("ORIGINAL")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                    Spacer()
                    Text("PIXELATED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.85))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            .frame(width: width, height: height)
        }
        .frame(width: width, height: height)
    }
}

// Subtle dark checkerboard pattern
public struct CheckerboardBackground: View {
    public var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 20
            let cols = Int(ceil(size.width / step))
            let rows = Int(ceil(size.height / step))
            
            for r in 0..<rows {
                for c in 0..<cols {
                    let isEven = (r + c) % 2 == 0
                    let color = isEven ? Color(white: 0.12) : Color(white: 0.15)
                    let rect = CGRect(x: CGFloat(c) * step, y: CGFloat(r) * step, width: step, height: step)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
