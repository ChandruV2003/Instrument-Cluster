import SwiftUI

/// A 270° dial with:
/// • progress arc + white needle + grey tail + red tip
/// • clamp at zero
/// • linear 60 Hz animation
/// • optional red notch for the posted speed-limit
struct SpeedometerView: View {
    var speedMPS:   Double          // from LocationManager
    var accelDelta: Double          // from MotionManager
    var speedLimit: Double?         // mph, nil ⇒ hide notch
    let maxMPH:     Double

    // clamp negative from accel integration
    private var rawSpeedMPS: Double { speedMPS + accelDelta }
    private var clampedMPS:  Double { max(0, rawSpeedMPS) }
    private var mph:         Double { clampedMPS * 2.23694 }

    var body: some View {
        GeometryReader { geo in
            let size        = min(geo.size.width, geo.size.height)
            let trackW      = size * 0.10
            let radius      = size / 2
            let needleLen   = radius * 0.78
            let sleeveLen    = needleLen * 0.28        // e.g. 28% of needle length
            let sleeveWidth  = trackW * 0.32           // match the main needle width
            let sleeveOffset = -(needleLen - sleeveLen/2)


            ZStack {
                // 1) background ring
                Circle()
                    .trim(from: 0, to: 0.75)
                    .rotation(.degrees(135))
                    .stroke(Color.secondary.opacity(0.15),
                            style: .init(lineWidth: trackW, lineCap: .round))

                // 2) progress arc (syncs exactly with needle)
                Circle()
                    .trim(from: 0,
                          to: min(CGFloat(mph / maxMPH), 1) * 0.75)
                    .rotation(.degrees(135))
                    .stroke(speedColour,
                            style: .init(lineWidth: trackW, lineCap: .round))
                    .animation(.linear(duration: 1.0/60.0), value: mph)

                // 3) posted speed-limit notch
                if let limit = speedLimit {
                    SpeedLimitNotch(limit: limit,
                                    dialMax: maxMPH,
                                    radius: radius,
                                    trackW: trackW)
                }

                // 4) white needle
                Needle(radius: needleLen,
                       width: trackW * 0.32,
                       colour: .primary,
                       angle: needleAngle)

                // 5) grey tail
                Needle(radius: needleLen * 0.32,
                       width: trackW * 0.22,
                       colour: .secondary.opacity(0.6),
                       angle: needleAngle + .degrees(180))

                // 6) red tip at exactly the needle’s end
                Capsule()
                    .fill(Color.red)
                    .frame(width: sleeveWidth, height: sleeveLen)
                    .offset(y: sleeveOffset)
                    .rotationEffect(needleAngle)
                    .shadow(radius: 1)

                // 7) hub
                Circle()
                    .fill(Color.primary)
                    .frame(width: trackW * 0.8)

                // 8) digital read-out
                VStack(spacing: 0) {
                    Text(mph, format: .number.precision(.fractionLength(0)))
                        .font(.system(size: size * 0.27,
                                      weight: .black,
                                      design: .rounded))
                    Text("MPH")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .offset(y: size * 0.21)
            }
        }
    }

    private var needleAngle: Angle {
        .degrees(min(max(mph / maxMPH, 0), 1) * 270 - 135)
    }
    private var speedColour: Color {
        guard let limit = speedLimit else { return .green }
        switch mph - limit {
            case ..<5:    return .green
            case 5..<10:  return .orange
            default:      return .red
        }
    }
}

/* reusable needle/tail */
private struct Needle: View {
    let radius: CGFloat
    let width:  CGFloat
    let colour: Color
    let angle:  Angle

    var body: some View {
        Capsule()
            .fill(colour)
            .frame(width: width, height: radius)
            .offset(y: -radius/2)
            .rotationEffect(angle)
            .shadow(radius: 1)
    }
}

/* tiny red notch on the outer rim */
private struct SpeedLimitNotch: View {
    let limit:   Double
    let dialMax: Double
    let radius:  CGFloat
    let trackW:  CGFloat

    var body: some View {
        let frac  = min(max(limit / dialMax, 0), 1)
        let angle = Angle.degrees(frac * 270 - 135)

        Capsule()
            .fill(Color.red)
            .frame(width: trackW * 0.22, height: trackW * 0.22)
            .offset(y: -radius + trackW * 0.11)
            .rotationEffect(angle)
    }
}

#Preview {
    SpeedometerView(speedMPS:   65/2.23694,
                    accelDelta: 0,
                    speedLimit: 55,
                    maxMPH:     160)
        .frame(width: 280, height: 280)
        .padding()
        .background(.black)
}
