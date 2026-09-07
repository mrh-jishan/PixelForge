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
                    Menu {
                        Button(action: { state.openImagePanel() }) {
                            Label("Open...", systemImage: "folder")
                        }
                        
                        Menu("Open Sample") {
                            Button("Synthwave Sunset") {
                                state.loadSampleSynthwave()
                            }
                            Button("Color Bars & Calibration Chart") {
                                state.loadSampleColorBars()
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { state.saveImagePanel() }) {
                            Label("Save As...", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: { state.copyToClipboard() }) {
                            Label("Copy to Clipboard", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Label("File", systemImage: "folder")
                    }
                    .help("File operations (Open, Save, Samples)")
                    
                    Button(action: { state.openImagePanel() }) {
                        Label("Open", systemImage: "square.and.arrow.down.on.square")
                    }
                    .help("Open an image file (⌘O)")
                    
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleOriginalPreview"))) { _ in
            state.showOriginalOnly.toggle()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoadSynthwaveRequested"))) { _ in
            state.loadSampleSynthwave()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoadColorBarsRequested"))) { _ in
            state.loadSampleColorBars()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetFilters"))) { _ in
            state.resetFilters()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ZoomInRequested"))) { _ in
            state.zoomIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ZoomOutRequested"))) { _ in
            state.zoomOut()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ActualSizeRequested"))) { _ in
            state.setActualSize()
        }
    }
}
