import CoreLocation

/// Finds the nearest airport. Shows the standard iOS "Allow location" alert the first time;
/// if the user declines (or location fails) it falls back to the device time zone.
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var finished = false
    var onResult: ((Airport, OriginMethod) -> Void)?

    func start() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        handle(manager.authorizationStatus)
    }

    private func handle(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            finish(Airports.fromTimeZone(), .timezone)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handle(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        finish(Airports.nearest(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude), .location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(Airports.fromTimeZone(), .timezone)
    }

    private func finish(_ airport: Airport, _ method: OriginMethod) {
        guard !finished else { return }
        finished = true
        DispatchQueue.main.async { self.onResult?(airport, method) }
    }
}
