import CoreMotion
import SwiftUI
import Combine

struct Tilt: Equatable { 
    var roll: Double
    var pitch: Double 
}

@MainActor
final class MotionManager: ObservableObject {
    @Published var gVector = CGVector.zero  // smoothed ±1 g
    @Published var tilt    = Tilt(roll: 0, pitch: 0)
    @Published var deltaV  = 0.0            // m/s integrated accel between GPS fixes
    
    private let mm = CMMotionManager()
    private var lastAccel = CGVector.zero
    private var lastUpdate = Date()
    
    // Performance optimization: ultra-high update rate for instant response
    private var updateInterval: TimeInterval = 1.0 / 120.0  // 120 Hz like modern instrument clusters
    private var isHighPerformanceMode = true
    
    // Orientation observer
    private var orientationCancellable: AnyCancellable?
    private var currentOrientation: UIDeviceOrientation = .unknown
    
    init() {
        // Observe orientation changes using modern NotificationCenter + Combine
        orientationCancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { _ in UIDevice.current.orientation }
            .filter { $0.isValidInterfaceOrientation || $0.isLandscape || $0.isPortrait }
            .removeDuplicates()
            .sink { [weak self] orientation in
                self?.currentOrientation = orientation
            }
        
        // Enable orientation notifications
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    deinit {
        // Cleanup orientation notifications
        // Note: Using MainActor.assumeIsolated since this is safe cleanup code
        MainActor.assumeIsolated {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
    }
    
    func start() {
        guard mm.isDeviceMotionAvailable else { return }
        
        mm.deviceMotionUpdateInterval = updateInterval
        
        mm.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let m = motion else { return }
            
            Task { @MainActor in
                self.processMotionUpdate(m)
            }
        }
    }
    
    func stop() {
        mm.stopDeviceMotionUpdates()
    }
    
    func setHighPerformanceMode(_ enabled: Bool) {
        isHighPerformanceMode = enabled
        updateInterval = enabled ? 1.0 / 120.0 : 1.0 / 60.0  // 120Hz high, 60Hz standard (both very responsive)
        
        if mm.isDeviceMotionActive {
            mm.deviceMotionUpdateInterval = updateInterval
        }
    }
    
    private func processMotionUpdate(_ m: CMDeviceMotion) {
        // ——— 1) dead-band + low-pass IMU accel ———
        let raw = CGVector(dx: m.userAcceleration.y,
                           dy: m.userAcceleration.x)
        
        // Adaptive dead-band: reduce road noise
        let dead: Double = 0.02
        var filtered = raw
        if abs(raw.dx) < dead { filtered.dx = 0 }
        if abs(raw.dy) < dead { filtered.dy = 0 }
        
        // Optimized low-pass filter with adaptive alpha
        let α = isHighPerformanceMode ? 0.15 : 0.25
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
        
        // ——— 3) Modern orientation-aware roll/pitch mapping ———
        let r = m.attitude.roll  * 180 / .pi
        let p = m.attitude.pitch * 180 / .pi
        
        // Use cached orientation for better performance
        let orientation = currentOrientation != .unknown ? currentOrientation : UIDevice.current.orientation
        
        switch orientation {
        case .landscapeLeft:
            tilt = Tilt(roll: p, pitch: -r)
        case .landscapeRight:
            tilt = Tilt(roll: -p, pitch: r)
        case .portrait:
            tilt = Tilt(roll: r, pitch: p)
        case .portraitUpsideDown:
            tilt = Tilt(roll: -r, pitch: -p)
        default:
            // Fallback to interface orientation for unknown device orientation
            tilt = Tilt(roll: r, pitch: p)
        }
    }
}

// Extension for orientation validation
private extension UIDeviceOrientation {
    var isValidInterfaceOrientation: Bool {
        switch self {
        case .portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
        }
    }
}
