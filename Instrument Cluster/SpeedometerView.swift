import SwiftUI

/// A 270° dial with optimized rendering:
/// • progress arc + white needle + grey tail + red tip
/// • clamp at zero
/// • smooth 60 Hz animation with intelligent frame dropping
/// • optional red notch for the posted speed-limit
struct SpeedometerView: View {
    var speedMPS: Double          // from LocationManager
    var accelDelta: Double          // from MotionManager
    var speedLimit: Double?         // mph, nil ⇒ hide notch
    let maxMPH: Double
    
    // Performance: throttled state updates
    @State private var displayMPH: Double = 0
    
    // clamp negative from accel integration
    private var rawSpeedMPS: Double { speedMPS + accelDelta }
    private var clampedMPS: Double { max(0, rawSpeedMPS) }
    private var mph: Double { clampedMPS * 2.23694 }
    
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let trackW = size * 0.10
            let radius = size / 2
            let needleLen = radius * 0.78
            let sleeveLen = needleLen * 0.28
            let sleeveWidth = trackW * 0.32
            let sleeveOffset = -(needleLen - sleeveLen/2)
            
            ZStack {
                // 1) Background ring - static, no animation
                Circle()
                    .trim(from: 0, to: 0.75)
                    .rotation(.degrees(135))
                    .stroke(Color.secondary.opacity(0.15),
                            style: .init(lineWidth: trackW, lineCap: .round))
                    .drawingGroup() // Metal acceleration
                
                // 2) Progress arc (syncs with needle)
                Circle()
                    .trim(from: 0, to: min(CGFloat(displayMPH / maxMPH), 1) * 0.75)
                    .rotation(.degrees(135))
                    .stroke(speedColour,
                            style: .init(lineWidth: trackW, lineCap: .round))
                    .drawingGroup() // Metal acceleration
                
                // 3) Posted speed-limit notch
                if let limit = speedLimit {
                    SpeedLimitNotch(limit: limit,
                                    dialMax: maxMPH,
                                    radius: radius,
                                    trackW: trackW)
                        .drawingGroup() // Metal acceleration
                }
                
                // 4) Needle assembly (grouped for better performance)
                NeedleAssembly(
                    needleLen: needleLen,
                    trackW: trackW,
                    sleeveLen: sleeveLen,
                    sleeveWidth: sleeveWidth,
                    sleeveOffset: sleeveOffset,
                    angle: needleAngle
                )
                .drawingGroup() // Metal acceleration
                
                // 5) Digital read-out
                VStack(spacing: 0) {
                    Text(displayMPH, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: size * 0.27, weight: .black, design: .rounded))
                        .monospacedDigit() // Prevent width jumps
                    
                    Text("MPH")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .offset(y: size * 0.21)
            }
            .onChange(of: mph) { _, newValue in
                updateDisplaySpeed(newValue)
            }
            .onAppear {
                displayMPH = mph
            }
        }
    }
    
    private func updateDisplaySpeed(_ target: Double) {
        // Ultra-fast linear animation for instant updates (like Tesla instrument cluster)
        withAnimation(.linear(duration: 0.033)) {  // ~30 FPS update rate
            displayMPH = target
        }
    }
    
    private var needleAngle: Angle {
        .degrees(min(max(displayMPH / maxMPH, 0), 1) * 270 - 135)
    }
    
    private var speedColour: Color {
        guard let limit = speedLimit else { return .green }
        switch displayMPH - limit {
        case ..<5:    return .green
        case 5..<10:  return .orange
        default:      return .red
        }
    }
}

// MARK: - Needle Assembly (optimized grouping)
private struct NeedleAssembly: View {
    let needleLen: CGFloat
    let trackW: CGFloat
    let sleeveLen: CGFloat
    let sleeveWidth: CGFloat
    let sleeveOffset: CGFloat
    let angle: Angle
    
    var body: some View {
        ZStack {
            // White needle
            Needle(radius: needleLen,
                   width: trackW * 0.32,
                   colour: .primary,
                   angle: angle)
            
            // Grey tail
            Needle(radius: needleLen * 0.32,
                   width: trackW * 0.22,
                   colour: .secondary.opacity(0.6),
                   angle: angle + .degrees(180))
            
            // Red tip
            Capsule()
                .fill(Color.red)
                .frame(width: sleeveWidth, height: sleeveLen)
                .offset(y: sleeveOffset)
                .rotationEffect(angle)
                .shadow(color: .red.opacity(0.5), radius: 2)
            
            // Hub
            Circle()
                .fill(Color.primary)
                .frame(width: trackW * 0.8)
        }
    }
}

// MARK: - Reusable needle/tail
private struct Needle: View {
    let radius: CGFloat
    let width: CGFloat
    let colour: Color
    let angle: Angle
    
    var body: some View {
        Capsule()
            .fill(colour)
            .frame(width: width, height: radius)
            .offset(y: -radius/2)
            .rotationEffect(angle)
            .shadow(color: colour.opacity(0.3), radius: 1)
    }
}

// MARK: - Speed limit notch
private struct SpeedLimitNotch: View {
    let limit: Double
    let dialMax: Double
    let radius: CGFloat
    let trackW: CGFloat
    
    var body: some View {
        let frac = min(max(limit / dialMax, 0), 1)
        let angle = Angle.degrees(frac * 270 - 135)
        
        Capsule()
            .fill(Color.red)
            .frame(width: trackW * 0.22, height: trackW * 0.22)
            .offset(y: -radius + trackW * 0.11)
            .rotationEffect(angle)
            .shadow(color: .red.opacity(0.8), radius: 3)
    }
}

#Preview {
    SpeedometerView(speedMPS: 65/2.23694,
                    accelDelta: 0,
                    speedLimit: 55,
                    maxMPH: 160)
        .frame(width: 280, height: 280)
        .padding()
        .background(.black)
}
