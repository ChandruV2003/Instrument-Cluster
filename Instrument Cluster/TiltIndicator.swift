import SwiftUI

struct TiltIndicator: View {
    var tilt: Tilt          // already bias-corrected upstream

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let rollR = -tilt.roll * .pi / 180

            ZStack {
                Circle().stroke(.secondary.opacity(0.3), lineWidth: 2)

                // horizon line (roll + pitch)
                let pitchFrac   = tilt.pitch / 45          // ±1 at about 45°
                let clampedFrac = max(-1, min(1, pitchFrac))
                let pitchOffset = CGFloat(clampedFrac) * h * 0.35

                Path { p in
                    p.move(to: .zero)
                    p.addLine(to: CGPoint(x: w, y: 0))
                }
                .stroke(.orange, lineWidth: 4)
                .offset(x: 0, y: h/2 - pitchOffset)
                .rotationEffect(.radians(rollR))

                VStack(spacing: 2) {
                    Text("Roll \(tilt.roll,  specifier: "%.0f")°")
                    Text("Pitch \(tilt.pitch, specifier: "%.0f")°")
                }
                .font(.system(size: geo.size.width * 0.10, weight: .bold))
                .foregroundStyle(.secondary)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: tilt)
        }
    }
}

#Preview {
    TiltIndicator(tilt: .init(roll: 15, pitch: -10))
        .frame(width: 160, height: 160)
        .padding()
        .background(.black)
}
