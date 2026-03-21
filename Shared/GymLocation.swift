import Foundation
import CoreLocation
import SwiftData

@Model
final class GymLocation {
    var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double // meters
    var isDefault: Bool
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        radius: Double = 100,
        isDefault: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.isDefault = isDefault
        self.createdAt = createdAt
    }

    static var planetFitness: GymLocation {
        GymLocation(
            name: "Planet Fitness",
            latitude: 40.7580,
            longitude: -73.9855,
            radius: 100,
            isDefault: true
        )
    }
}
