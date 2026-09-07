import SwiftUI

public struct SidebarView: View {
    @ObservedObject var state: AppState
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Category Picker (Full-Width Styled Menu)
                VStack(alignment: .leading, spacing: 8) {
                    Text("MODE")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Menu {
                        ForEach(FilterCategory.allCases) { cat in
                            Button(action: {
                                state.filterParams.category = cat
                                state.scheduleProcess()
                            }) {
                                HStack {
                                    Label(cat.rawValue, systemImage: cat.iconName)
                                    if state.filterParams.category == cat {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: state.filterParams.category.iconName)
                                .foregroundColor(.accentColor)
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 20)
                            
                            Text(state.filterParams.category.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .frame(maxWidth: .infinity)
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
        .frame(minWidth: 270, idealWidth: 290, maxWidth: 330)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Pixelate Controls
    private var pixelateControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PIXELATION")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            // Block Size
            VStack(alignment: .leading, spacing: 6) {
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
                
                // Quick size chips (Full Width distribution)
                HStack(spacing: 6) {
                    ForEach([4, 8, 16, 24, 32, 48], id: \.self) { sz in
                        Button("\(sz)") {
                            state.filterParams.pixelSize = Double(sz)
                            state.scheduleProcess()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Int(state.filterParams.pixelSize) == sz ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(Int(state.filterParams.pixelSize) == sz ? .white : .primary)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 2)
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
            
            // Channel Mode (Full-Width Styled Menu)
            Menu {
                ForEach(RGBChannelMode.allCases) { m in
                    Button(action: {
                        state.filterParams.rgbMode = m
                        state.scheduleProcess()
                    }) {
                        HStack {
                            Text(m.rawValue)
                            if state.filterParams.rgbMode == m {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(state.filterParams.rgbMode.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: .infinity)
            
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
            
            // B&W Mode (Full-Width Styled Menu)
            Menu {
                ForEach(BWMode.allCases) { m in
                    Button(action: {
                        state.filterParams.bwMode = m
                        state.scheduleProcess()
                    }) {
                        HStack {
                            Text(m.rawValue)
                            if state.filterParams.bwMode == m {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(state.filterParams.bwMode.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: .infinity)
            
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
    
    // MARK: - Retro Palette Controls (Consistent Visual Cards)
    private var retroPaletteControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("RETRO PALETTES")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
            
            // Full-Width Visual Palette Cards
            VStack(spacing: 7) {
                ForEach(RetroPalette.allCases) { pal in
                    let isSelected = (state.filterParams.retroPalette == pal)
                    Button(action: {
                        state.filterParams.retroPalette = pal
                        state.scheduleProcess()
                    }) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(pal.rawValue)
                                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .primary : .secondary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 12))
                                }
                            }
                            
                            // Visual Color Swatch Strip
                            HStack(spacing: 3) {
                                ForEach(Array(pal.colors.enumerated()), id: \.offset) { _, c in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(
                                            red: Double((c >> 16) & 0xFF) / 255.0,
                                            green: Double((c >> 8) & 0xFF) / 255.0,
                                            blue: Double(c & 0xFF) / 255.0
                                        ))
                                        .frame(height: 14)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                            )
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(isSelected ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
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
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(AppPreset.allCases) { preset in
                    Button(action: {
                        state.applyPreset(preset)
                    }) {
                        Text(preset.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 4)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(7)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
