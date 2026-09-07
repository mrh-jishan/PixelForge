import SwiftUI

public struct ContentView: View {
    @StateObject private var state = AppState()
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(state: state)
                .navigationSplitViewColumnWidth(min: 270, ideal: 290, max: 340)
        } detail: {
            VStack(spacing: 0) {
                // Canvas Area
                CanvasViewport(state: state)
                
                // Bottom HUD Bar
                HUDView(state: state)
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: { state.openImagePanel() }) {
                        Label("Open Image", systemImage: "folder")
                    }
                    .help("Open an image file (⌘O)")
                    
                    Menu {
                        Button("Synthwave Sunset") {
                            state.loadSampleSynthwave()
                        }
                        Button("Color Bars & Calibration Chart") {
                            state.loadSampleColorBars()
                        }
                    } label: {
                        Label("Samples", systemImage: "sparkles")
                    }
                    .help("Load procedural test scenes")
                    
                    Divider()
                    
                    Button(action: { state.copyToClipboard() }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .help("Copy pixelated image to clipboard (⌘C)")
                    
                    Button(action: { state.saveImagePanel() }) {
                        Label("Export Image", systemImage: "square.and.arrow.up")
                    }
                    .help("Export pixelated image as PNG/JPEG (⌘S)")
                    
                    Divider()
                    
                    Button(action: {
                        withAnimation {
                            state.showSplitCompare.toggle()
                        }
                    }) {
                        Label("Split Compare", systemImage: "rectangle.split.2x1")
                    }
                    .help("Toggle side-by-side comparison slider (⌘D)")
                    
                    Button(action: {
                        state.showOriginalOnly.toggle()
                    }) {
                        Label("Original Preview", systemImage: state.showOriginalOnly ? "eye.slash.fill" : "eye")
                    }
                    .help("Toggle original image view")
                    
                    Button(action: { state.resetFilters() }) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .help("Reset filter parameters (⌘R)")
                }
            }
        }
        .navigationTitle(state.imageTitle)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenImageRequested"))) { _ in
            state.openImagePanel()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SaveImageRequested"))) { _ in
            state.saveImagePanel()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CopyImageRequested"))) { _ in
            state.copyToClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleSplitCompare"))) { _ in
            withAnimation {
                state.showSplitCompare.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetFilters"))) { _ in
            state.resetFilters()
        }
    }
}
