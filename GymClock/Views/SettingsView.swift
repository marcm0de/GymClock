import SwiftUI
import SwiftData
import MapKit

struct SettingsView: View {
    @EnvironmentObject var geofenceManager: GeofenceManager
    @Query(sort: \GymLocation.name) private var gyms: [GymLocation]
    @Environment(\.modelContext) private var modelContext

    @State private var showAddGym = false
    @State private var showingDeleteAlert = false
    @State private var gymToDelete: GymLocation?

    @AppStorage("weeklyGoalDays") private var weeklyGoalDays: Int = 4

    var body: some View {
        NavigationStack {
            List {
                // Weekly Goal
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundStyle(.green)
                            Text("Weekly Goal")
                                .font(.headline)
                            Spacer()
                            Text("\(weeklyGoalDays) days/week")
                                .foregroundStyle(.green)
                                .font(.subheadline.bold())
                        }

                        Stepper("Days per week: \(weeklyGoalDays)", value: $weeklyGoalDays, in: 1...7)
                    }
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Set how many days per week you want to work out. Track your progress in Stats.")
                }

                // Gym Locations
                Section {
                    ForEach(gyms) { gym in
                        GymRow(gym: gym)
                    }
                    .onDelete(perform: deleteGym)

                    Button(action: { showAddGym = true }) {
                        Label("Add Gym Location", systemImage: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Text("Gym Locations")
                } footer: {
                    Text("GymClock uses geofencing to automatically detect when you arrive at and leave your gym.")
                }

                // Geofencing
                Section("Location Services") {
                    HStack {
                        Text("Status")
                        Spacer()
                        statusBadge
                    }

                    HStack {
                        Text("Monitoring")
                        Spacer()
                        Text(geofenceManager.isMonitoring ? "Active" : "Inactive")
                            .foregroundStyle(geofenceManager.isMonitoring ? .green : .secondary)
                    }

                    if !geofenceManager.isAuthorized {
                        Button("Grant Location Access") {
                            geofenceManager.requestAuthorization()
                        }
                    }

                    Button("Refresh Geofences") {
                        geofenceManager.startMonitoring(locations: gyms)
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    if let githubURL = URL(string: "https://github.com/marcm0de/GymClock") {
                        Link(destination: githubURL) {
                            HStack {
                                Text("GitHub")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddGym) {
                AddGymView()
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(geofenceManager.isAuthorized ? .green : .red)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        switch geofenceManager.authorizationStatus {
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "When In Use"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Set"
        @unknown default: return "Unknown"
        }
    }

    private func deleteGym(at offsets: IndexSet) {
        for index in offsets {
            let gym = gyms[index]
            geofenceManager.stopMonitoring(for: gym)
            modelContext.delete(gym)
        }
        try? modelContext.save()
    }
}

// MARK: - Gym Row

struct GymRow: View {
    let gym: GymLocation

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(gym.name)
                        .font(.headline)
                    if gym.isDefault {
                        Text("DEFAULT")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green, in: Capsule())
                    }
                }

                Text("Radius: \(Int(gym.radius))m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "location.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Add Gym View

struct AddGymView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var geofenceManager: GeofenceManager

    @State private var name = ""
    @State private var radius: Double = 100
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @State private var selectedCoordinate = CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)

    var body: some View {
        NavigationStack {
            Form {
                Section("Gym Details") {
                    TextField("Gym Name", text: $name)

                    VStack(alignment: .leading) {
                        Text("Detection Radius: \(Int(radius))m")
                        Slider(value: $radius, in: 50...500, step: 25)
                            .tint(.green)
                    }
                }

                Section("Location") {
                    Map(position: $position) {
                        Marker(name.isEmpty ? "Gym" : name, coordinate: selectedCoordinate)
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        selectedCoordinate = context.camera.centerCoordinate
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Center the map on your gym location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGym() }
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveGym() {
        let gym = GymLocation(
            name: name,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            radius: radius
        )
        modelContext.insert(gym)
        try? modelContext.save()

        // Start monitoring the new gym
        let allGyms = (try? modelContext.fetch(FetchDescriptor<GymLocation>())) ?? []
        geofenceManager.startMonitoring(locations: allGyms)

        dismiss()
    }
}

#Preview {
    SettingsView()
        .environmentObject(GeofenceManager.shared)
        .modelContainer(for: [WorkoutSession.self, GymLocation.self], inMemory: true)
}
