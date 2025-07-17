import SwiftUI

struct SpeedGauge: View {
    var speed: Double                         // metres/sec
    private var mph: Double      { speed * 2.23694 }
    private let maxMPH: Double = 160

    var body: some View {
        Gauge(value: mph, in: 0...maxMPH) {
            Text("mph")
        } currentValueLabel: {
            Text(Int(mph).description)
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.5)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(AngularGradient(
            gradient: .init(colors: [.green, .yellow, .orange, .red]),
            center: .center))
        .animation(.easeOut(duration: 0.15), value: mph)
    }
}

#Preview {
    SpeedGauge(speed: 30)      // ≈ 67 mph
        .frame(width: 240, height: 240)
        .padding()
        .background(.black)
}
