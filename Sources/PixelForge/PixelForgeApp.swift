import SwiftUI
import AppKit

@main
struct PixelForgeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            // First Menu Tab: Standard macOS "File" Menu
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenImageRequested"), object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Menu("Open Sample") {
                    Button("Synthwave Sunset") {
                        NotificationCenter.default.post(name: NSNotification.Name("LoadSynthwaveRequested"), object: nil)
                    }
                    Button("Color Bars & Calibration Chart") {
                        NotificationCenter.default.post(name: NSNotification.Name("LoadColorBarsRequested"), object: nil)
                    }
                }
                
                Divider()
                
                Button("Save As...") {
                    NotificationCenter.default.post(name: NSNotification.Name("SaveImageRequested"), object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Divider()
            }
            
            // Edit Menu: Copy to Clipboard
            CommandGroup(replacing: .pasteboard) {
                Button("Copy Processed Image") {
                    NotificationCenter.default.post(name: NSNotification.Name("CopyImageRequested"), object: nil)
                }
                .keyboardShortcut("c", modifiers: .command)
            }
            
            // View Menu: Display toggles & shortcuts
            CommandMenu("View") {
                Button("Zoom In") {
                    NotificationCenter.default.post(name: NSNotification.Name("ZoomInRequested"), object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Zoom Out") {
                    NotificationCenter.default.post(name: NSNotification.Name("ZoomOutRequested"), object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Button("Actual Size") {
                    NotificationCenter.default.post(name: NSNotification.Name("ActualSizeRequested"), object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)
                
                Divider()
                
                Button("Toggle Split Compare") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleSplitCompare"), object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Toggle Original Preview") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleOriginalPreview"), object: nil)
                }
                .keyboardShortcut(" ", modifiers: [])
                
                Divider()
                
                Button("Reset Filters") {
                    NotificationCenter.default.post(name: NSNotification.Name("ResetFilters"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
