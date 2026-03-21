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
- 🔥 **Estimated calorie tracking** based on workout type and duration

### 🏷️ Workout Types
- Tag sessions as **Weights**, **Cardio**, **Mixed**, or **Other**
- Type-specific calorie estimates (cardio burns more!)
- Visual icons for each workout type in history

### 📝 Session Notes
- Jot down what you worked on during each session
- Notes visible in history for easy reference
- Never forget what you did last leg day again

### 📊 Stats & Streaks
- **Day streaks** — consecutive days with gym visits (🟢 green when active, ⚪ grey when broken)
- **Week streaks** — consecutive weeks with at least one visit
- 🎯 **Weekly goal tracking** — set your target days per week with progress bar
- Weekly bar charts showing daily gym time
- Monthly overviews with session count, total time, and calories
- 🏆 **Personal Best** indicator for your longest session ever

### 📅 History
- **Weekly summaries** with total time and calories per week
- Grouped by week with individual session details
- 🏆 Personal Best badge on your longest session
- Workout type icons and calorie counts on every entry
- Swipe to delete sessions

### 💬 Daily Motivation
- Fresh motivational quote every day on the main screen
- 30 unique quotes to keep you inspired
- Because sometimes you need that extra push

### ⌚ Apple Watch
- Full standalone watch app
- **Extra large timer font** — see your time at a glance
- Live estimated calories during sessions
- Quick check-in/check-out
- Session history with crown scroll
- Daily motivational quotes
- 🏆 Personal best indicators
- **Watch complications:**
  - Session/streak at a glance
  - ⚡ **Quick Start** — tap to immediately begin a session

### ❤️ HealthKit Integration
- Automatically logs gym sessions to Apple Health
- Recorded as "Other" workout type
- Seamless integration with your health data

---

## 📱 Screenshots

### iPhone

| Active Session | History | Stats | Settings |
|:-:|:-:|:-:|:-:|
| ![Active Session](screenshots/ios-active.png) | ![History](screenshots/ios-history.png) | ![Stats](screenshots/ios-stats.png) | ![Settings](screenshots/ios-settings.png) |

### Apple Watch

| Timer | History | Complication | Quick Start |
|:-:|:-:|:-:|:-:|
| ![Watch Active](screenshots/watch-active.png) | ![Watch History](screenshots/watch-history.png) | ![Complication](screenshots/watch-complication.png) | ![Quick Start](screenshots/watch-quickstart.png) |

> 📸 Screenshots coming soon — contributions welcome!

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | SwiftUI |
| Persistence | SwiftData |
| Location | CoreLocation (Geofencing) |
| Health | HealthKit |
| Watch | WatchKit + watchOS 10 |
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
│   ├── WorkoutSession.swift         # Workout session model + WorkoutType enum
│   ├── GeofenceManager.swift        # CoreLocation geofencing manager
│   ├── SessionTracker.swift         # Session lifecycle + HealthKit
│   ├── DateFormatters.swift         # Date/time formatting utilities
│   └── MotivationalQuotes.swift     # Daily motivational quotes
├── GymClock/                        # iOS App
│   ├── GymClockApp.swift            # App entry point
│   ├── ContentView.swift            # Tab-based navigation
│   ├── Info.plist                   # iOS configuration
│   ├── Assets.xcassets/             # App icon & colors
│   └── Views/
│       ├── ActiveSessionView.swift  # Live session timer + workout type picker
│       ├── HistoryView.swift        # Session history with weekly summaries
│       ├── StatsView.swift          # Charts, streaks, goals, personal bests
│       └── SettingsView.swift       # Gym management, weekly goals
├── GymClockWatch/                   # watchOS App
│   ├── GymClockWatchApp.swift       # Watch app entry point
│   ├── WatchContentView.swift       # Watch navigation
│   ├── WatchActiveSessionView.swift # Watch timer (large font) + calories
│   ├── WatchHistoryView.swift       # Watch history with crown scroll
│   ├── Info.plist                   # watchOS configuration
│   └── Assets.xcassets/             # Watch app icon & colors
├── GymClockWatch Extension/         # Watch Complications
│   └── GymClockComplication.swift   # WidgetKit complications + Quick Start
├── Package.swift                    # SPM reference
├── README.md
├── CONTRIBUTING.md
├── LICENSE
└── .gitignore
```

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### Development Setup

1. **Fork & clone** the repository
   ```bash
   git clone https://github.com/your-fork/GymClock.git
   cd GymClock
   ```

2. **Open in Xcode 15+** and configure signing with your team

3. **Required capabilities:**
   - Location Services (Always)
   - HealthKit
   - App Groups

4. **Run on a physical device** for full geofencing/HealthKit support

### Guidelines

- Follow Swift style conventions and use SwiftUI best practices
- Keep shared code in the `Shared/` directory
- Test on both iPhone and Apple Watch when possible
- Write descriptive commit messages
- Update README if adding user-facing features

### Quick Start

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test on device
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include device, OS version, and steps to reproduce for bugs
- Screenshots/recordings are always helpful

---

## 🗺️ Roadmap

### Coming Soon
- [ ] Apple Watch workout session (extended runtime for background tracking)
- [ ] iOS Home Screen widget showing streak & weekly progress
- [ ] Siri Shortcuts — "Hey Siri, check me into the gym"
- [ ] Push notifications — streak reminders & weekly summaries

### Planned
- [ ] Social features — share streaks with friends
- [ ] Workout templates — pre-built routines for different workout types
- [ ] Export data as CSV/JSON for analysis
- [ ] Dark/light theme customization
- [ ] Rest timer between sets
- [ ] Body weight tracking integration
- [ ] Gym occupancy estimates (crowdsourced)

### Exploring
- [ ] AI-powered workout suggestions based on history
- [ ] Heart rate zone tracking via Apple Watch sensors
- [ ] Integration with popular fitness apps (Strong, Hevy, etc.)
- [ ] Apple Watch Ultra depth/altitude tracking for outdoor workouts

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Built with SwiftUI, SwiftData, and CoreLocation
- Inspired by the simple goal of knowing "how long was I actually at the gym?"
- Motivational quotes curated to keep you grinding 💪

---

**Made with 💪 by [Marcus Fequiere](https://github.com/yourusername)**
