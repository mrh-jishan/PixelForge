import SwiftUI

public struct SidebarView: View {
    @ObservedObject var state: AppState
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // File Section (First Section)
                VStack(alignment: .leading, spacing: 8) {
                    Text("FILE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button(action: { state.openImagePanel() }) {
                            Label("Open...", systemImage: "folder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        
                        Menu {
                            Button("Synthwave Sunset") {
                                state.loadSampleSynthwave()
                            }
                            Button("Color Bars & Calibration") {
                                state.loadSampleColorBars()
                            }
                        } label: {
                            Image(systemName: "sparkles")
                                .padding(4)
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 28)
                        .help("Load procedural sample scenes")
                    }
                    
                    if state.originalCGImage != nil {
                        HStack {
                            Text(state.imageTitle)
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(state.imageDimensions.width))×\(Int(state.imageDimensions.height))")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // Category Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("MODE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Picker("Mode", selection: Binding(
                        get: { state.filterParams.category },
                        set: { state.filterParams.category = $0; state.scheduleProcess() }
                    )) {
                        ForEach(FilterCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                Divider()
                
                // Dynamic Controls based on Category
                switch state.filterParams.category {
                case .pixelate:
                    pixelateControls
                case .rgbChannels:
                    rgbChannelControls
                case .blackAndWhite:
                    blackAndWhiteControls
                case .retroPalette:
                    retroPaletteControls
                case .crtArcade:
                    crtArcadeControls
                }
                
                Divider()
                
                // Global Adjustments
                globalColorControls
                
                Divider()
                
                // Presets Shelf
                presetsShelf
            }
            .padding(16)
        }
        .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Pixelate Controls
    private var pixelateControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PIXELATION")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            // Block Size
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pixel Size")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.pixelSize)) px")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.pixelSize },
                    set: { state.filterParams.pixelSize = $0; state.scheduleProcess() }
                ), in: 1...80, step: 1)
                
                // Quick size chips
                HStack(spacing: 6) {
                    ForEach([4, 8, 16, 24, 32, 48], id: \.self) { sz in
                        Button("\(sz)") {
                            state.filterParams.pixelSize = Double(sz)
                            state.scheduleProcess()
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Int(state.filterParams.pixelSize) == sz ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(Int(state.filterParams.pixelSize) == sz ? .white : .primary)
                        .cornerRadius(4)
                    }
                }
                .padding(.top, 4)
            }
            
            // Pixel Grid Overlay
            Toggle("Pixel Grid Mesh", isOn: Binding(
                get: { state.filterParams.showPixelGrid },
                set: { state.filterParams.showPixelGrid = $0; state.scheduleProcess() }
            ))
            .font(.subheadline)
            
            if state.filterParams.showPixelGrid {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Grid Opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(state.filterParams.gridOpacity * 100))%")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { state.filterParams.gridOpacity },
                        set: { state.filterParams.gridOpacity = $0; state.scheduleProcess() }
                    ), in: 0.05...0.8)
                }
            }
            
            // Posterize / Quantize
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Color Quantization")
                        .font(.subheadline)
                    Spacer()
                    Text(state.filterParams.posterizeLevels <= 0 ? "Off" : "\(Int(state.filterParams.posterizeLevels)) levels")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.posterizeLevels },
                    set: { state.filterParams.posterizeLevels = $0; state.scheduleProcess() }
                ), in: 0...32, step: 2)
            }
        }
    }
    
    // MARK: - RGB Channel Controls
    private var rgbChannelControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RGB CHANNELS & SPLIT")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            // Channel Mode
            Picker("Channel", selection: Binding(
                get: { state.filterParams.rgbMode },
                set: { state.filterParams.rgbMode = $0; state.scheduleProcess() }
            )) {
                ForEach(RGBChannelMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            
            // Pixel Size
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pixel Size")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.pixelSize)) px")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.pixelSize },
                    set: { state.filterParams.pixelSize = $0; state.scheduleProcess() }
                ), in: 1...64, step: 1)
            }
            
            // Chromatic Shift
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("3D Chromatic Aberration")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.chromaticShiftX)) px")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.chromaticShiftX },
                    set: { state.filterParams.chromaticShiftX = $0; state.scheduleProcess() }
                ), in: -30...30, step: 1)
            }
            
            // Channel Gains
            VStack(alignment: .leading, spacing: 8) {
                Text("Channel Gains")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("R").foregroundColor(.red).bold().frame(width: 16)
                    Slider(value: Binding(
                        get: { state.filterParams.rGain },
                        set: { state.filterParams.rGain = $0; state.scheduleProcess() }
                    ), in: 0...2)
                }
                HStack {
                    Text("G").foregroundColor(.green).bold().frame(width: 16)
                    Slider(value: Binding(
                        get: { state.filterParams.gGain },
                        set: { state.filterParams.gGain = $0; state.scheduleProcess() }
                    ), in: 0...2)
                }
                HStack {
                    Text("B").foregroundColor(.blue).bold().frame(width: 16)
                    Slider(value: Binding(
                        get: { state.filterParams.bGain },
                        set: { state.filterParams.bGain = $0; state.scheduleProcess() }
                    ), in: 0...2)
                }
            }
        }
    }
    
    // MARK: - Black & White Controls
    private var blackAndWhiteControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BLACK & WHITE / DITHER")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            Picker("Mode", selection: Binding(
                get: { state.filterParams.bwMode },
                set: { state.filterParams.bwMode = $0; state.scheduleProcess() }
            )) {
                ForEach(BWMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            
            Text(state.filterParams.bwMode.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Threshold slider for 1-bit threshold
            if state.filterParams.bwMode == .threshold {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Threshold")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(state.filterParams.threshold * 100))%")
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { state.filterParams.threshold },
                        set: { state.filterParams.threshold = $0; state.scheduleProcess() }
                    ), in: 0...1)
                }
            }
            
            // Pixel Size
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pixel Size")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.pixelSize)) px")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.pixelSize },
                    set: { state.filterParams.pixelSize = $0; state.scheduleProcess() }
                ), in: 1...64, step: 1)
            }
            
            Toggle("Pixel Grid Mesh", isOn: Binding(
                get: { state.filterParams.showPixelGrid },
                set: { state.filterParams.showPixelGrid = $0; state.scheduleProcess() }
            ))
            .font(.subheadline)
        }
    }
    
    // MARK: - Retro Palette Controls
    private var retroPaletteControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RETRO PALETTES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            Picker("Palette", selection: Binding(
                get: { state.filterParams.retroPalette },
                set: { state.filterParams.retroPalette = $0; state.scheduleProcess() }
            )) {
                ForEach(RetroPalette.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            
            // Palette Swatches
            HStack(spacing: 4) {
                ForEach(Array(state.filterParams.retroPalette.colors.enumerated()), id: \.offset) { _, c in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(
                            red: Double((c >> 16) & 0xFF) / 255.0,
                            green: Double((c >> 8) & 0xFF) / 255.0,
                            blue: Double(c & 0xFF) / 255.0
                        ))
                        .frame(height: 20)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            
            // Pixel Size
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pixel Size")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.pixelSize)) px")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.pixelSize },
                    set: { state.filterParams.pixelSize = $0; state.scheduleProcess() }
                ), in: 1...64, step: 1)
            }
            
            Toggle("Pixel Grid Mesh", isOn: Binding(
                get: { state.filterParams.showPixelGrid },
                set: { state.filterParams.showPixelGrid = $0; state.scheduleProcess() }
            ))
            .font(.subheadline)
        }
    }
    
    // MARK: - CRT Arcade Controls
    private var crtArcadeControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CRT ARCADE MONITOR")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Pixel Size")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.pixelSize)) px")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.pixelSize },
                    set: { state.filterParams.pixelSize = $0; state.scheduleProcess() }
                ), in: 1...40, step: 1)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Scanline Intensity")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.crtIntensity * 100))%")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.crtIntensity },
                    set: { state.filterParams.crtIntensity = $0; state.scheduleProcess() }
                ), in: 0.1...0.9)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Scanline Density")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(state.filterParams.crtDensity)) px")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { state.filterParams.crtDensity },
                    set: { state.filterParams.crtDensity = $0; state.scheduleProcess() }
                ), in: 1...4, step: 1)
            }
        }
    }
    
    // MARK: - Global Adjustments
    private var globalColorControls: some View {
        DisclosureGroup("Color Adjustments") {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Brightness")
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%+.2f", state.filterParams.brightness))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { state.filterParams.brightness },
                        set: { state.filterParams.brightness = $0; state.scheduleProcess() }
                    ), in: -0.4...0.4)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Contrast")
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.2f", state.filterParams.contrast))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { state.filterParams.contrast },
                        set: { state.filterParams.contrast = $0; state.scheduleProcess() }
                    ), in: 0.5...2.0)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Saturation")
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.2f", state.filterParams.saturation))
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { state.filterParams.saturation },
                        set: { state.filterParams.saturation = $0; state.scheduleProcess() }
                    ), in: 0.0...2.0)
                }
                
                Button("Reset Colors") {
                    state.filterParams.brightness = 0.0
                    state.filterParams.contrast = 1.0
                    state.filterParams.saturation = 1.0
                    state.scheduleProcess()
                }
                .font(.caption)
                .buttonStyle(.borderless)
            }
            .padding(.top, 6)
        }
        .font(.subheadline)
    }
    
    // MARK: - Presets Shelf
    private var presetsShelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PRESETS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(AppPreset.allCases) { preset in
                    Button(action: {
                        state.applyPreset(preset)
                    }) {
                        Text(preset.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}
