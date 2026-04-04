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
    @Published var monitoringError: String?

    var onEnterGym: ((String) -> Void)?
    var onExitGym: ((String) -> Void)?
    /// Called when location permission is revoked while monitoring
    var onPermissionRevoked: (() -> Void)?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        #if os(iOS)
        // Background location updates require UIBackgroundModes location entitlement
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        #endif
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

        guard !locations.isEmpty else {
            // No gyms configured — nothing to monitor
            Task { @MainActor in
                self.isMonitoring = false
            }
            return
        }

        // iOS limits region monitoring to 20 regions per app
        let locationsToMonitor = Array(locations.prefix(Self.maxMonitoredRegions))
        if locations.count > Self.maxMonitoredRegions {
            let skipped = locations.count - Self.maxMonitoredRegions
            print("Warning: Only monitoring first \(Self.maxMonitoredRegions) gym locations (iOS limit). \(skipped) locations skipped.")
            Task { @MainActor in
                self.monitoringError = "Only monitoring \(Self.maxMonitoredRegions) of \(locations.count) gyms (iOS limit)"
            }
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

        Task { @MainActor in
            self.isMonitoring = true
        }
    }

    func stopAllMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        Task { @MainActor in
            self.isMonitoring = false
        }
    }

    func stopMonitoring(for location: GymLocation) {
        let region = locationManager.monitoredRegions.first {
            $0.identifier == location.id.uuidString
        }
        if let region = region {
            locationManager.stopMonitoring(for: region)
        }
        // Update monitoring state if no regions left
        if locationManager.monitoredRegions.isEmpty {
            Task { @MainActor in
                self.isMonitoring = false
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = newStatus

            // Handle permission revoked while monitoring
            if newStatus == .denied || newStatus == .restricted {
                if self.isMonitoring {
                    self.stopAllMonitoring()
                    self.monitoringError = "Location permission revoked — geofencing disabled"
                    self.onPermissionRevoked?()
                }
            }
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
        let regionId = region?.identifier ?? "unknown"
        print("Geofence monitoring failed for region \(regionId): \(error.localizedDescription)")
        Task { @MainActor in
            self.monitoringError = "Monitoring failed for region \(regionId)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
        Task { @MainActor in
            self.monitoringError = "Location error: \(error.localizedDescription)"
        }
    }
}
