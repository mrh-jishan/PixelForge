import SwiftUI
import AppKit

/// A native macOS popup picker that automatically expands to 100% of available width.
public struct FullWidthPicker<T: Hashable>: View {
    public let title: String
    @Binding public var selection: T
    public let options: [(value: T, title: String, icon: String?)]
    
    public init(
        _ title: String = "",
        selection: Binding<T>,
        options: [(value: T, title: String, icon: String?)]
    ) {
        self.title = title
        self._selection = selection
        self.options = options
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            FullWidthPopUpRepresentable(
                selection: $selection,
                options: options
            )
            .frame(maxWidth: .infinity)
            .frame(height: 24)
        }
    }
}

public struct FullWidthPopUpRepresentable<T: Hashable>: NSViewRepresentable {
    @Binding public var selection: T
    public let options: [(value: T, title: String, icon: String?)]
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = .systemFont(ofSize: 12, weight: .regular)
        
        populateItems(button)
        selectCurrent(button)
        return button
    }
    
    public func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.parent = self
        if button.numberOfItems != options.count {
            populateItems(button)
        }
        selectCurrent(button)
    }
    
    private func populateItems(_ button: NSPopUpButton) {
        button.removeAllItems()
        for opt in options {
            button.addItem(withTitle: opt.title)
            if let iconName = opt.icon, let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
                let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
                button.lastItem?.image = img.withSymbolConfiguration(config)
            }
        }
    }
    
    private func selectCurrent(_ button: NSPopUpButton) {
        if let index = options.firstIndex(where: { $0.value == selection }) {
            if button.indexOfSelectedItem != index {
                button.selectItem(at: index)
            }
        }
    }
    
    public class Coordinator: NSObject {
        var parent: FullWidthPopUpRepresentable
        
        init(_ parent: FullWidthPopUpRepresentable) {
            self.parent = parent
        }
        
        @objc func selectionChanged(_ sender: NSPopUpButton) {
            let index = sender.indexOfSelectedItem
            if index >= 0 && index < parent.options.count {
                parent.selection = parent.options[index].value
            }
        }
    }
}
