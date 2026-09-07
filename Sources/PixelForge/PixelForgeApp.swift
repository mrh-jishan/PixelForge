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
            CommandGroup(replacing: .newItem) {}
            
            CommandMenu("Image") {
                Button("Open Image...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenImageRequested"), object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save Processed Image...") {
                    NotificationCenter.default.post(name: NSNotification.Name("SaveImageRequested"), object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Copy to Clipboard") {
                    NotificationCenter.default.post(name: NSNotification.Name("CopyImageRequested"), object: nil)
                }
                .keyboardShortcut("c", modifiers: .command)
            }
            
            CommandMenu("View") {
                Button("Toggle Split Compare") {
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleSplitCompare"), object: nil)
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Reset Filters") {
                    NotificationCenter.default.post(name: NSNotification.Name("ResetFilters"), object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}
