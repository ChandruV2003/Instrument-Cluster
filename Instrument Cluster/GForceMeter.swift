import SwiftUI

struct GForceMeter: View {
    var gVector: CGVector
    
    @State private var peakVector = CGVector.zero
    @State private var lastPeakTime = Date()
    @State private var displayVector = CGVector.zero
    
    private let ringColor = Color.secondary.opacity(0.3)
    
    private var gLong: Double { Double(-displayVector.dy) }
    private var gLat: Double { Double(displayVector.dx) }
    private var gMag: Double { hypot(gLong, gLat) }
    
    var body: some View {
        GeometryReader { geo in
            let R = geo.size.width / 2
            let vx = CGFloat(displayVector.dx).clamped(to: -1...1)
            let vy = CGFloat(displayVector.dy).clamped(to: -1...1)
            
            ZStack {
                // Static rings - no animation, Metal accelerated
                RingsView()
                    .drawingGroup()
                
                // Live dot with smooth animation
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 14, height: 14)
                    .position(x: R + vx * R, y: R - vy * R)
                    .shadow(color: Color.accentColor.opacity(0.6), radius: 4)
                
                // Ghost peak dot with fade
                if ghostOpacity > 0.1 {
                    Circle()
                        .fill(Color.yellow.opacity(ghostOpacity))
                        .frame(width: 12, height: 12)
                        .position(
                            x: R + CGFloat(peakVector.dx).clamped(to: -1...1) * R,
                            y: R - CGFloat(peakVector.dy).clamped(to: -1...1) * R
                        )
                        .shadow(color: Color.yellow.opacity(ghostOpacity * 0.8), radius: 3)
                }
                
                // Numeric read-out with monospaced digits
                Text(gMag, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: geo.size.width * 0.24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .onChange(of: gVector) { _, new in
                updateGVector(new)
            }
            .onAppear {
                displayVector = gVector
            }
        }
        .drawingGroup() // Enable Metal rendering for entire view
    }
    
    private func updateGVector(_ new: CGVector) {
        // Smooth update with spring animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
            displayVector = new
        }
        
        // Track peak
        let mag = hypot(new.dx, new.dy)
        if mag > hypot(peakVector.dx, peakVector.dy) {
            peakVector = new
            lastPeakTime = Date()
        }
    }
    
    private var ghostOpacity: Double {
        max(0, 1 - Date().timeIntervalSince(lastPeakTime) / 3)
    }
}

// MARK: - Rings View (static, optimized)
private struct RingsView: View {
    private let ringColor = Color.secondary.opacity(0.3)
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor, lineWidth: 2)
            
            Circle()
                .stroke(ringColor, lineWidth: 1)
                .scaleEffect(0.5)
            
            // Add center crosshair for better reference
            Path { path in
                path.move(to: CGPoint(x: 0.5, y: 0.45))
                path.addLine(to: CGPoint(x: 0.5, y: 0.55))
                path.move(to: CGPoint(x: 0.45, y: 0.5))
                path.addLine(to: CGPoint(x: 0.55, y: 0.5))
            }
            .stroke(ringColor, lineWidth: 1)
            .aspectRatio(1, contentMode: .fit)
        }
    }
}

/* helper */
private extension Comparable {
    func clamped(to r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}

#Preview {
    GForceMeter(gVector: .init(dx: 0.55, dy: -0.2))
        .frame(width: 160, height: 160)
        .padding()
        .background(.black)
}
