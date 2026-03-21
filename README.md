# 🏋️ GymClock

**Auto-track your gym sessions with Apple Watch + iPhone.**

GymClock uses geofencing to automatically detect when you arrive at and leave your gym — no manual start/stop needed. Just walk in, work out, walk out. GymClock handles the rest.

![Platform](https://img.shields.io/badge/Platform-iOS%2017%20%7C%20watchOS%2010-green)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## ✨ Features

### 🎯 Auto-Detection
- **Geofencing** — Automatically checks you in when you arrive at your gym and checks you out when you leave
- **Planet Fitness** included as default, fully configurable
- Add unlimited gym locations with custom detection radii

### ⏱️ Live Session Tracking
- Real-time elapsed time on both iPhone and Apple Watch
- Check-in/check-out timestamps
- Manual check-in option when you need it

### 📊 Stats & Streaks
- **Day streaks** — consecutive days with gym visits
- **Week streaks** — consecutive weeks with at least one visit
- Weekly bar charts showing daily gym time
- Monthly overviews with session count, total time, and averages
- All-time longest session trophy

### 📅 History
- Daily, weekly, and monthly views
- Grouped by date with check-in/check-out times
- Swipe to delete sessions

### ⌚ Apple Watch
- Full standalone watch app
- Live elapsed timer during sessions
- Quick check-in/check-out
- Session history on your wrist
- **Watch complications** — see today's session or streak at a glance

### ❤️ HealthKit Integration
- Automatically logs gym sessions to Apple Health
- Recorded as "Other" workout type
- Seamless integration with your health data

---

## 📱 Screenshots

| iPhone | Apple Watch |
|--------|-------------|
| ![Active Session](screenshots/ios-active.png) | ![Watch Active](screenshots/watch-active.png) |
| ![History](screenshots/ios-history.png) | ![Watch History](screenshots/watch-history.png) |
| ![Stats](screenshots/ios-stats.png) | ![Complication](screenshots/watch-complication.png) |
| ![Settings](screenshots/ios-settings.png) | |

> Screenshots coming soon — contributions welcome!

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Location | CoreLocation (Geofencing) |
| Health | HealthKit |
| Watch | WatchKit + WatchOS 10 |
| Complications | WidgetKit |
| Charts | Swift Charts |
| Min iOS | 17.0 |
| Min watchOS | 10.0 |

---

## 📦 Installation

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ device or simulator
- watchOS 10.0+ (for watch features)
- Apple Developer account (for on-device testing with location)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/GymClock.git
   cd GymClock
   ```

2. **Open in Xcode**
   - Create a new Xcode project (iOS App with Watch App)
   - Add the source files from each directory to the corresponding targets
   - Or use `File > Add Files to "GymClock"...` to import the project structure

3. **Configure signing**
   - Select your development team
   - Update bundle identifiers:
     - iOS: `com.yourname.GymClock`
     - watchOS: `com.yourname.GymClock.watchkitapp`
     - Complication: `com.yourname.GymClock.watchkitapp.complication`

4. **Enable capabilities**
   - Background Modes → Location updates
   - HealthKit
   - App Groups (for sharing data between iOS and watchOS)

5. **Build and run** on your device

### Important Notes
- **Geofencing requires "Always" location permission** — the app will prompt on first launch
- **On-device testing recommended** — simulators don't fully support geofencing
- **HealthKit** requires a physical device

---

## 📂 Project Structure

```
GymClock/
├── Shared/                          # Shared code between iOS and watchOS
│   ├── GymLocation.swift            # Gym location model (SwiftData)
│   ├── WorkoutSession.swift         # Workout session model (SwiftData)
│   ├── GeofenceManager.swift        # CoreLocation geofencing manager
│   ├── SessionTracker.swift         # Session lifecycle + HealthKit
│   └── DateFormatters.swift         # Date/time formatting utilities
├── GymClock/                        # iOS App
│   ├── GymClockApp.swift            # App entry point
│   ├── ContentView.swift            # Tab-based navigation
│   ├── Info.plist                   # iOS configuration
│   ├── Assets.xcassets/             # App icon & colors
│   └── Views/
│       ├── ActiveSessionView.swift  # Live session timer
│       ├── HistoryView.swift        # Session history list
│       ├── StatsView.swift          # Charts, streaks, stats
│       └── SettingsView.swift       # Gym management, settings
├── GymClockWatch/                   # watchOS App
│   ├── GymClockWatchApp.swift       # Watch app entry point
│   ├── WatchContentView.swift       # Watch navigation
│   ├── WatchActiveSessionView.swift # Watch timer view
│   ├── WatchHistoryView.swift       # Watch history view
│   ├── Info.plist                   # watchOS configuration
│   └── Assets.xcassets/             # Watch app icon & colors
├── GymClockWatch Extension/         # Watch Complications
│   └── GymClockComplication.swift   # WidgetKit complications
├── Package.swift                    # SPM reference
├── README.md
├── LICENSE
├── CONTRIBUTING.md
└── .gitignore
```

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Quick start:
1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📋 Roadmap

- [ ] Apple Watch workout session (extended runtime)
- [ ] Workout type categorization (cardio, strength, etc.)
- [ ] Social features — share streaks with friends
- [ ] Siri Shortcuts integration
- [ ] Widget for iOS home screen
- [ ] Dark/light theme customization
- [ ] Export data as CSV
- [ ] Notifications — streak reminders, weekly summaries

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with SwiftUI, SwiftData, and CoreLocation
- Inspired by the simple goal of knowing "how long was I actually at the gym?"

---

**Made with 💪 by [Marcus Fequiere](https://github.com/yourusername)**
