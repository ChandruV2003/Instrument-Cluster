import SwiftUI

struct CalibrationView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var motion = MotionManager()

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 28) {

                Spacer(minLength: geo.size.height * 0.05)

                Image(systemName: "scope")
                    .font(.system(size: geo.size.height * 0.12))
                    .padding(.bottom, 6)

                Text("Calibration")
                    .font(.system(size: geo.size.height * 0.065, weight: .bold))

                Text(
                    "Place your phone level on the dashboard, then tap **Calibrate**. "
                  + "This will zero the roll- and pitch-reference so the tilt dial reads 0°."
                )
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .font(.body)

                Spacer()

                Button {
                    app.rollBias  = motion.tilt.roll
                    app.pitchBias = motion.tilt.pitch
                    app.isCalibrated = true
                } label: {
                    Text("Calibrate")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(Color(.systemBackground))
                }
                // button width ≈ 50 % of screen
                .padding(.horizontal, geo.size.width * 0.25)

                Spacer(minLength: geo.size.height * 0.08)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).ignoresSafeArea())
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

#Preview { CalibrationView().environmentObject(AppState()) }
