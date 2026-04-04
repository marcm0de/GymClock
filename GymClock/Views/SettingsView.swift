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
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(.green.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "target")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                            Text("Weekly Goal")
                                .font(.headline)
                            Spacer()
                            Text("\(weeklyGoalDays) days")
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.1), in: Capsule())
                        }

                        Stepper("Days per week: \(weeklyGoalDays)", value: $weeklyGoalDays, in: 1...7)

                        // Visual dots
                        HStack(spacing: 6) {
                            ForEach(1...7, id: \.self) { day in
                                Circle()
                                    .fill(day <= weeklyGoalDays ? Color.green : Color(.systemGray5))
                                    .frame(width: 10, height: 10)
                                    .animation(.spring(response: 0.3), value: weeklyGoalDays)
                            }
                        }
                    }
                } header: {
                    Label("Goals", systemImage: "flag.fill")
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
                            .font(.subheadline.bold())
                    }
                } header: {
                    Label("Gym Locations", systemImage: "building.2.fill")
                } footer: {
                    Text("GymClock uses geofencing to automatically detect when you arrive at and leave your gym.")
                }

                // Geofencing
                Section {
                    HStack {
                        Label("Status", systemImage: "location.fill")
                        Spacer()
                        statusBadge
                    }

                    HStack {
                        Label("Monitoring", systemImage: "antenna.radiowaves.left.and.right")
                        Spacer()
                        Text(geofenceManager.isMonitoring ? "Active" : "Inactive")
                            .font(.subheadline)
                            .foregroundStyle(geofenceManager.isMonitoring ? .green : .secondary)
                    }

                    if !geofenceManager.isAuthorized {
                        Button(action: { geofenceManager.requestAuthorization() }) {
                            Label("Grant Location Access", systemImage: "location.circle")
                                .foregroundStyle(.blue)
                        }
                    }

                    Button(action: { geofenceManager.startMonitoring(locations: gyms) }) {
                        Label("Refresh Geofences", systemImage: "arrow.clockwise")
                            .foregroundStyle(.green)
                    }
                } header: {
                    Label("Location Services", systemImage: "location.circle.fill")
                }

                // About
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    if let githubURL = URL(string: "https://github.com/marcm0de/GymClock") {
                        Link(destination: githubURL) {
                            HStack {
                                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                                Spacer()
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Label("About", systemImage: "heart.fill")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAddGym) {
                AddGymView()
            }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "location.circle.fill")
                    .font(.body)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(gym.name)
                        .font(.subheadline.bold())
                    if gym.isDefault {
                        Text("DEFAULT")
                            .font(.system(size: 9, weight: .bold))
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
        }
        .padding(.vertical, 2)
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

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Detection Radius")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(radius))m")
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                        }
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
                        .fontWeight(.bold)
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
