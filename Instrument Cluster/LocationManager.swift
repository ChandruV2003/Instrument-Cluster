import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var speedMPS: Double = .zero      // raw GPS m/s
    @Published var altitudeFt: Double = .zero    // metres → feet
    @Published var lastLocation: CLLocation?     // drives speed-limit fetches
    
    private let mgr: CLLocationManager = {
        let m = CLLocationManager()
        m.desiredAccuracy = kCLLocationAccuracyBestForNavigation  // Optimized for automotive
        m.activityType = .automotiveNavigation
        m.distanceFilter = kCLDistanceFilterNone  // No distance filter - instant updates like Tesla
        m.pausesLocationUpdatesAutomatically = false
        m.allowsBackgroundLocationUpdates = false  // Battery optimization
        m.showsBackgroundLocationIndicator = false
        return m
    }()
    
    // Performance: high-frequency updates for instant speedometer response
    private var lastSignificantUpdate: Date?
    private let significantUpdateInterval: TimeInterval = 0.066  // ~15 updates/second (like Tesla)
    
    // Minimal speed smoothing for instant response (like Tesla cluster)
    private var speedHistory: [Double] = []
    private let speedHistorySize = 2  // Minimal smoothing - 2 samples only
    
    override init() {
        super.init()
    }
    
    nonisolated func start() {
        Task { @MainActor in
            mgr.delegate = self
            mgr.requestWhenInUseAuthorization()
            mgr.startUpdatingLocation()
        }
    }
    
    nonisolated func stop() {
        Task { @MainActor in
            mgr.stopUpdatingLocation()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locs: [CLLocation]) {
        Task { @MainActor in
            await processLocationUpdate(locs)
        }
    }
    
    private func processLocationUpdate(_ locs: [CLLocation]) async {
        guard let loc = locs.last else { return }
        
        // Throttle updates for performance
        let now = Date()
        if let lastUpdate = lastSignificantUpdate,
           now.timeIntervalSince(lastUpdate) < significantUpdateInterval {
            return
        }
        lastSignificantUpdate = now
        
        // Validate location quality
        guard loc.horizontalAccuracy >= 0,
              loc.horizontalAccuracy <= 50 else {  // Reject poor accuracy
            return
        }
        
        // Publish location (only if significantly different or first update)
        if shouldPublishLocation(loc) {
            lastLocation = loc
        }
        
        // GPS speed with smoothing
        if loc.speed >= 0 {
            speedHistory.append(loc.speed)
            if speedHistory.count > speedHistorySize {
                speedHistory.removeFirst()
            }
            // Use median for better noise rejection
            speedMPS = median(speedHistory)
        }
        
        // Altitude → feet with rounding for stability
        altitudeFt = (loc.altitude * 3.28084).rounded()
    }
    
    private func shouldPublishLocation(_ newLoc: CLLocation) -> Bool {
        guard let lastLoc = lastLocation else { return true }
        
        // Only publish if moved significantly (20+ meters) to reduce API calls
        let distance = newLoc.distance(from: lastLoc)
        return distance >= 20
    }
    
    private func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2
        } else {
            return sorted[mid]
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            handleAuthorizationChange(manager.authorizationStatus)
        }
    }
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            mgr.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            mgr.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
