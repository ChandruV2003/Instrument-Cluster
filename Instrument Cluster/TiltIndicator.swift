import SwiftUI

struct TiltIndicator: View {
    var tilt: Tilt          // already bias-corrected upstream
    
    @State private var displayTilt = Tilt(roll: 0, pitch: 0)
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let rollR = -displayTilt.roll * .pi / 180
            
            ZStack {
                // Static outer ring - Metal accelerated
                Circle()
                    .stroke(.secondary.opacity(0.3), lineWidth: 2)
                    .drawingGroup()
                
                // Horizon line with pitch offset
                HorizonLine(pitch: displayTilt.pitch, width: w, height: h)
                    .rotationEffect(.radians(rollR))
                    .drawingGroup()
                
                // Numerical readout with monospaced digits
                VStack(spacing: 2) {
                    Text("Roll \(displayTilt.roll, specifier: "%.0f")°")
                        .monospacedDigit()
                    Text("Pitch \(displayTilt.pitch, specifier: "%.0f")°")
                        .monospacedDigit()
                }
                .font(.system(size: geo.size.width * 0.10, weight: .bold))
                .foregroundStyle(.secondary)
            }
            .onChange(of: tilt) { _, new in
                updateTilt(new)
            }
            .onAppear {
                displayTilt = tilt
            }
        }
    }
    
    private func updateTilt(_ new: Tilt) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0)) {
            displayTilt = new
        }
    }
}

// MARK: - Horizon Line (optimized)
private struct HorizonLine: View {
    let pitch: Double
    let width: CGFloat
    let height: CGFloat
    
    private var pitchOffset: CGFloat {
        let pitchFrac = pitch / 45          // ±1 at about 45°
        let clampedFrac = max(-1, min(1, pitchFrac))
        return CGFloat(clampedFrac) * height * 0.35
    }
    
    var body: some View {
        Path { p in
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: width, y: 0))
        }
        .stroke(LinearGradient(
            colors: [.orange.opacity(0.6), .orange, .orange.opacity(0.6)],
            startPoint: .leading,
            endPoint: .trailing
        ), lineWidth: 4)
        .offset(x: 0, y: height/2 - pitchOffset)
        .shadow(color: .orange.opacity(0.5), radius: 2)
    }
}

#Preview {
    TiltIndicator(tilt: .init(roll: 15, pitch: -10))
        .frame(width: 160, height: 160)
        .padding()
        .background(.black)
}
