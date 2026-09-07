import SwiftUI
import AppKit
import UniformTypeIdentifiers

public struct CanvasViewport: View {
    @ObservedObject var state: AppState
    
    @State private var dragStartPan: CGSize = .zero
    @State private var isDraggingSplitter: Bool = false
    @State private var isTargetedForDrop: Bool = false
    @State private var pinchStartZoom: CGFloat? = nil
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background dark checkerboard
                CheckerboardBackground()
                    .ignoresSafeArea()
                
                // Native Trackpad Pinch & Mouse Wheel Interceptor
                NativeGestureView(
                    onMagnify: { delta in
                        let factor = 1.0 + delta
                        let newZoom = max(0.05, min(state.zoomScale * factor, 32.0))
                        state.zoomScale = newZoom
                    },
                    onScrollZoom: { delta in
                        let factor = 1.0 + delta
                        let newZoom = max(0.05, min(state.zoomScale * factor, 32.0))
                        state.zoomScale = newZoom
                    },
                    onScrollPan: { dx, dy in
                        if !isDraggingSplitter {
                            state.panOffset = CGSize(
                                width: state.panOffset.width + dx,
                                height: state.panOffset.height + dy
                            )
                        }
                    }
                )
                .ignoresSafeArea()
                
                if let original = state.originalCGImage {
                    let imageSize = state.imageDimensions
                    let displayW = imageSize.width * state.zoomScale
                    let displayH = imageSize.height * state.zoomScale
                    
                    // Main image layer with pan & zoom
                    ZStack {
                        if state.showOriginalOnly {
                            PixelSharpImageView(cgImage: original)
                                .frame(width: displayW, height: displayH)
                        } else if state.showSplitCompare, let processed = state.processedCGImage {
                            SplitCompareView(
                                original: original,
                                processed: processed,
                                width: displayW,
                                height: displayH,
                                splitPosition: $state.splitPosition,
                                isDraggingSplitter: $isDraggingSplitter
                            )
                        } else if let processed = state.processedCGImage {
                            PixelSharpImageView(cgImage: processed)
                                .frame(width: displayW, height: displayH)
                        } else {
                            PixelSharpImageView(cgImage: original)
                                .frame(width: displayW, height: displayH)
                        }
                    }
                    .offset(state.panOffset)
                    .gesture(
                        // Drag to pan image
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
                    .simultaneousGesture(
                        // SwiftUI Pinch Gesture with linear baseline anchor
                        MagnificationGesture()
                            .onChanged { scale in
                                if pinchStartZoom == nil {
                                    pinchStartZoom = state.zoomScale
                                }
                                if let base = pinchStartZoom {
                                    state.zoomScale = max(0.05, min(base * scale, 32.0))
                                }
                            }
                            .onEnded { _ in
                                pinchStartZoom = nil
                            }
                    )
                    .onAppear {
                        dragStartPan = state.panOffset
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
                
                // Top HUD / Status badge
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

// Native AppKit Gesture View for frictionless trackpad & wheel events
public struct NativeGestureView: NSViewRepresentable {
    public var onMagnify: (CGFloat) -> Void
    public var onScrollZoom: (CGFloat) -> Void
    public var onScrollPan: (CGFloat, CGFloat) -> Void
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> EventTrackingNSView {
        let view = EventTrackingNSView()
        view.coordinator = context.coordinator
        return view
    }
    
    public func updateNSView(_ nsView: EventTrackingNSView, context: Context) {
        context.coordinator.parent = self
    }
    
    public class Coordinator {
        var parent: NativeGestureView
        init(_ parent: NativeGestureView) {
            self.parent = parent
        }
    }
    
    public class EventTrackingNSView: NSView {
        weak var coordinator: Coordinator?
        
        public override var acceptsFirstResponder: Bool { true }
        
        public override func magnify(with event: NSEvent) {
            coordinator?.parent.onMagnify(event.magnification)
        }
        
        public override func scrollWheel(with event: NSEvent) {
            let isZoomModifier = event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option)
            if isZoomModifier {
                let delta = event.hasPreciseScrollingDeltas
                    ? (event.scrollingDeltaY * 0.006)
                    : (event.scrollingDeltaY * 0.035)
                coordinator?.parent.onScrollZoom(delta)
            } else {
                // Two finger pan
                let dx = event.scrollingDeltaX
                let dy = event.scrollingDeltaY
                coordinator?.parent.onScrollPan(dx, dy)
            }
        }
    }
}

// Crisp Nearest-Neighbor Image Display with Image Caching
public struct PixelSharpImageView: NSViewRepresentable {
    public let cgImage: CGImage
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator {
        var lastCGImageID: CFHashCode?
        var cachedNSImage: NSImage?
    }
    
    public func makeNSView(context: Context) -> NSImageView {
        let view = NSImageView()
        view.imageScaling = .scaleAxesIndependently
        view.wantsLayer = true
        view.layer?.magnificationFilter = .nearest
        view.layer?.minificationFilter = .nearest
        return view
    }
    
    public func updateNSView(_ nsView: NSImageView, context: Context) {
        let currentID = CFHash(cgImage)
        if context.coordinator.lastCGImageID != currentID {
            context.coordinator.lastCGImageID = currentID
            let newImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            context.coordinator.cachedNSImage = newImage
            nsView.image = newImage
        } else if nsView.image == nil {
            nsView.image = context.coordinator.cachedNSImage
        }
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
            // Processed Image behind
            PixelSharpImageView(cgImage: processed)
                .frame(width: width, height: height)
            
            // Original Image clipped
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
            
            // Splitter handle
            let splitX = -width / 2.0 + (width * splitPosition)
            
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: height)
                    .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 0)
                
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
