import SwiftUI
import CoreLocation

struct DashboardView: View {
    @EnvironmentObject private var app: AppState
    @StateObject private var motion   = MotionManager()
    @StateObject private var location = LocationManager()

    private var tilt: Tilt {
        Tilt(roll:  motion.tilt.roll  - app.rollBias,
             pitch: motion.tilt.pitch - app.pitchBias)
    }

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let big         = min(geo.size.width, geo.size.height) * 0.75
            let flank       = big * 0.62
            let gap         = flank * 0.14

            ZStack(alignment: .topLeading) {
                Color(.systemBackground).ignoresSafeArea()

                // ———  Three centred dials ———
                if isLandscape {
                    let totalW = flank + big + flank + gap*2
                    HStack(spacing: gap) {
                        TiltIndicator(tilt: tilt)
                            .frame(width: flank, height: flank)
                        SpeedometerView(
                            speedMPS:   location.speedMPS,
                            accelDelta: motion.deltaV,
                            speedLimit: app.speedLimitMPH,
                            maxMPH:     160)
                            .frame(width: big, height: big)
                        GForceMeter(gVector: motion.gVector)
                            .frame(width: flank, height: flank)
                    }
                    .frame(width: totalW)
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: .center)
                } else {
                    VStack(spacing: gap) {
                        SpeedometerView(
                            speedMPS:   location.speedMPS,
                            accelDelta: motion.deltaV,
                            speedLimit: app.speedLimitMPH,
                            maxMPH:     160)
                            .frame(width: big, height: big)
                        TiltIndicator(tilt: tilt)
                            .frame(width: flank, height: flank)
                        GForceMeter(gVector: motion.gVector)
                            .frame(width: flank, height: flank)
                    }
                    .frame(maxWidth: .infinity,
                           maxHeight: .infinity,
                           alignment: .center)
                }

                // ——— Overlay chips (speed, altitude) ———
                VStack(alignment: .leading, spacing: 8) {
                    if let sl = app.speedLimitMPH {
                        ChipView(icon: "speedometer",
                                 text: "\(Int(sl)) mph")
                    }
                    ChipView(icon: "mountain.2.fill",
                             text: "\(Int(location.altitudeFt)) ft")
                }
                .padding(.top, 12)
                .padding(.leading, 16)
            }
            // double-tap → recalibrate
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { app.isCalibrated = false }
            // fetch speed-limit on every new GPS fix
            .onChange(of: location.lastLocation) { oldLoc, newLoc in
                guard let loc = newLoc else { return }
                Task {
                    do {
                        if let sl = try await SpeedLimitService.fetchSpeedLimit(
                            for: loc.coordinate)
                        {
                            await MainActor.run { app.speedLimitMPH = sl }
                        }
                    } catch {
                        print("SpeedLimit fetch error:", error)
                    }
                }
            }

            .onAppear {
                motion.start()
                location.start()
            }
            .onDisappear {
                motion.stop()
                location.stop()
            }
        }
    }
}

#Preview {
    DashboardView().environmentObject(AppState())
        .frame(width: 600, height: 340)
}
