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

    /// Maximum number of regions iOS allows per app
    static let maxMonitoredRegions = 20

    func startMonitoring(locations: [GymLocation]) {
        guard isAuthorized else {
            requestAuthorization()
            return
        }

        stopAllMonitoring()

        // iOS limits region monitoring to 20 regions per app
        let locationsToMonitor = Array(locations.prefix(Self.maxMonitoredRegions))
        if locations.count > Self.maxMonitoredRegions {
            print("Warning: Only monitoring first \(Self.maxMonitoredRegions) gym locations (iOS limit). \(locations.count - Self.maxMonitoredRegions) locations skipped.")
        }

        for location in locationsToMonitor {
            let region = CLCircularRegion(
                center: location.coordinate,
                radius: min(location.radius, locationManager.maximumRegionMonitoringDistance),
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
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        Task { @MainActor in
            self.lastEnteredRegion = circularRegion.identifier
        }
        onEnterGym?(circularRegion.identifier)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        Task { @MainActor in
            self.lastExitedRegion = circularRegion.identifier
        }
        onExitGym?(circularRegion.identifier)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Geofence monitoring failed for region \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
}
