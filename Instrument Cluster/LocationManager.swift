import CoreLocation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var speedMPS:   Double   = .zero   // raw GPS m/s
    @Published var altitudeFt: Double   = .zero   // metres → feet
    @Published var lastLocation: CLLocation?      // drives speed-limit fetches

    private let mgr: CLLocationManager = {
        let m = CLLocationManager()
        m.desiredAccuracy                 = kCLLocationAccuracyBest
        m.activityType                    = .automotiveNavigation
        m.distanceFilter                  = kCLDistanceFilterNone
        m.pausesLocationUpdatesAutomatically = false
        return m
    }()

    func start() {
        mgr.delegate = self
        mgr.requestWhenInUseAuthorization()
        mgr.startUpdatingLocation()
    }

    func stop() {
        mgr.stopUpdatingLocation()
    }

    func locationManager(_ mgr: CLLocationManager,
                         didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }

        // publish for DashboardView
        lastLocation = loc

        // GPS speed (m/s)
        if loc.speed >= 0 {
            speedMPS = loc.speed
        }

        // altitude → feet
        altitudeFt = loc.altitude * 3.28084
    }
}
