import SwiftUI

struct GForceMeter: View {
    var gVector: CGVector

    @State private var peakVector = CGVector.zero
    @State private var lastPeakTime = Date()

    private let ringColor = Color.secondary.opacity(0.3)

    private var gLong: Double { Double(-gVector.dy) }
    private var gLat:  Double { Double( gVector.dx) }
    private var gMag:  Double { hypot(gLong, gLat) }

    var body: some View {
        GeometryReader { geo in
            let R  = geo.size.width / 2
            let vx = CGFloat(gVector.dx).clamped(to: -1...1)
            let vy = CGFloat(gVector.dy).clamped(to: -1...1)

            ZStack {
                Circle().stroke(ringColor, lineWidth: 2)
                Circle().stroke(ringColor, lineWidth: 1).scaleEffect(0.5)

                // live dot
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 12, height: 12)
                    .position(x: R + vx * R, y: R - vy * R)

                // ghost peak dot
                Circle()
                    .fill(Color.yellow.opacity(ghostOpacity))
                    .frame(width: 12, height: 12)
                    .position(
                        x: R + CGFloat(peakVector.dx).clamped(to: -1...1) * R,
                        y: R - CGFloat(peakVector.dy).clamped(to: -1...1) * R
                    )

                // numeric read-out
                Text(gMag, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: geo.size.width * 0.24,
                                  weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .animation(.easeOut(duration: 0.05), value: gVector)
        }
        // new two-parameter closure (oldValue, newValue)
        .onChange(of: gVector) { _, new in
            let mag = hypot(new.dx, new.dy)
            if mag > hypot(peakVector.dx, peakVector.dy) {
                peakVector   = new
                lastPeakTime = Date()
            }
        }
    }

    private var ghostOpacity: Double {
        max(0, 1 - Date().timeIntervalSince(lastPeakTime) / 3)
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
