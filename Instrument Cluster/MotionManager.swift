import CoreMotion
import SwiftUI
import UIKit      // for UIDevice.current.orientation

struct Tilt: Equatable { var roll: Double; var pitch: Double }

final class MotionManager: ObservableObject {
    @Published var gVector = CGVector.zero  // smoothed ±1 g
    @Published var tilt    = Tilt(roll: 0, pitch: 0)
    @Published var deltaV  = 0.0            // m/s integrated accel between GPS fixes

    private let mm         = CMMotionManager()
    private var lastAccel  = CGVector.zero
    private var lastUpdate = Date()

    func start() {
        guard mm.isDeviceMotionAvailable else { return }

        mm.deviceMotionUpdateInterval = 1.0 / 60.0   // 60 Hz

        mm.startDeviceMotionUpdates(to: .main) { [self] m, _ in
            guard let m else { return }

            // ——— 1) dead-band + low-pass IMU accel ———
            let raw = CGVector(dx: m.userAcceleration.y,
                               dy: m.userAcceleration.x)

            // kill the little road-buzz
            let dead: Double = 0.02
            var filtered = raw
            if abs(raw.dx) < dead { filtered.dx = 0 }
            if abs(raw.dy) < dead { filtered.dy = 0 }

            // α = 0.15 low-pass
            let α = 0.15
            lastAccel.dx = α * filtered.dx + (1-α) * lastAccel.dx
            lastAccel.dy = α * filtered.dy + (1-α) * lastAccel.dy
            self.gVector = lastAccel

            // ——— 2) integrate forward accel → bridge GPS lag ———
            let now = Date()
            let dt  = now.timeIntervalSince(lastUpdate)
            lastUpdate = now

            // forward axis ≈ -dy in landscape
            self.deltaV += (-filtered.dy) * 9.80665 * dt
            // decay drift over 2 s
            self.deltaV *= pow(0.5, dt / 2.0)

            // ——— 3) roll / pitch mapping per orientation ———
            let r = m.attitude.roll  * 180 / .pi
            let p = m.attitude.pitch * 180 / .pi

            switch UIDevice.current.orientation {
            case .landscapeLeft:
                tilt = Tilt(roll:  p, pitch: -r)
            case .landscapeRight:
                tilt = Tilt(roll: -p, pitch:  r)
            default:
                tilt = Tilt(roll:  r, pitch:  p)
            }
        }
    }

    func stop() {
        mm.stopDeviceMotionUpdates()
    }
}
