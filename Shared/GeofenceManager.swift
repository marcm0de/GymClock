import Foundation
import CoreLocation
import SwiftData
import Combine

final class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = GeofenceManager()

    private let locationManager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isMonitoring = false
    @Published var lastEnteredRegion: String?
    @Published var lastExitedRegion: String?

    var onEnterGym: ((String) -> Void)?
    var onExitGym: ((String) -> Void)?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways
    }

    // MARK: - Geofencing

    func startMonitoring(locations: [GymLocation]) {
        guard isAuthorized else {
            requestAuthorization()
            return
        }

        stopAllMonitoring()

        for location in locations {
            let region = CLCircularRegion(
                center: location.coordinate,
                radius: location.radius,
                identifier: location.id.uuidString
            )
            region.notifyOnEntry = true
            region.notifyOnExit = true
            locationManager.startMonitoring(for: region)
        }

        isMonitoring = true
    }

    func stopAllMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        isMonitoring = false
    }

    func stopMonitoring(for location: GymLocation) {
        let region = locationManager.monitoredRegions.first {
            $0.identifier == location.id.uuidString
        }
        if let region = region {
            locationManager.stopMonitoring(for: region)
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        lastEnteredRegion = circularRegion.identifier
        onEnterGym?(circularRegion.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        lastExitedRegion = circularRegion.identifier
        onExitGym?(circularRegion.identifier)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Geofence monitoring failed: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
}
