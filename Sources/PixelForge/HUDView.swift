import SwiftUI

public struct HUDView: View {
    @ObservedObject var state: AppState
    
    public var body: some View {
        HStack(spacing: 16) {
            // Resolution & Pixel Grid Stats
            HStack(spacing: 8) {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                Text("\(Int(state.imageDimensions.width)) × \(Int(state.imageDimensions.height)) px")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Image(systemName: "square.grid.2x2")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
                Text("\(state.effectiveGridSize.width) × \(state.effectiveGridSize.height) blocks")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Performance Latency Pill (Metal GPU)
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 10))
                Text(String(format: "%.2f ms", state.processingDurationMs))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                Text("(Metal GPU)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.35))
            .cornerRadius(5)
            
            // Zoom Controls
            HStack(spacing: 4) {
                Button(action: { state.zoomOut() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                
                Text("\(Int(state.zoomScale * 100))%")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .frame(minWidth: 42)
                
                Button(action: { state.zoomIn() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                
                Button("1:1") {
                    state.setActualSize()
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.1))
                .cornerRadius(4)
            }
            
            // Split Compare Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    state.showSplitCompare.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.split.2x1")
                    Text("Split View")
                }
                .font(.system(size: 11, weight: state.showSplitCompare ? .bold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(state.showSplitCompare ? Color.accentColor : Color.white.opacity(0.1))
                .foregroundColor(state.showSplitCompare ? .white : .primary)
                .cornerRadius(5)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.primary.opacity(0.08)),
            alignment: .top
        )
    }
}
