# GymClock — Product Roadmap

> A living document tracking planned features and milestones.

---

## v1.0 — ✅ Core (Current)

Auto-detect gym visits via geofencing, manual check-in/out, session timer, calorie estimates, history, streaks, stats, Apple Watch companion, and watchOS complications.

---

## v1.1 — Apple Health Deep Integration

**Goal:** Export rich workout data to Apple Health, not just basic workout summaries.

| Feature | Description | Effort |
|---|---|---|
| Workout type mapping | Map GymClock workout types (Weights, Cardio, Mixed) to specific `HKWorkoutActivityType` values | S |
| Heart rate integration | Read heart rate samples during active sessions (from Apple Watch) and display live/avg BPM | M |
| Energy burned samples | Write per-minute calorie samples alongside the workout for granular Health graphs | M |
| Workout route | Optionally attach a workout route for cardio sessions (runs to/from gym) | S |
| Health dashboard | In-app view showing resting heart rate trends, weekly energy, and workout frequency from HealthKit | L |
| Export to CSV | Export session history as CSV for personal analysis | S |

**Estimated total effort:** 4–6 weeks

---

## v1.2 — Social Features

**Goal:** Share achievements and compete with friends to boost motivation.

| Feature | Description | Effort |
|---|---|---|
| Share streak card | Generate a shareable image card showing current streak and stats | M |
| Challenge friends | Create time-bound challenges (e.g., "most sessions this month") via CloudKit or share links | L |
| Leaderboard | Weekly/monthly leaderboard among connected friends | L |
| Achievement badges | Unlock badges for milestones (100 sessions, 30-day streak, 1000 hours) | M |
| Activity feed | See friends' recent check-ins (opt-in, privacy-first) | M |
| iMessage integration | Share workout summaries directly via Messages | S |

**Estimated total effort:** 8–10 weeks

---

## v1.3 — Workout Templates

**Goal:** Pre-set workout routines with built-in interval timers.

| Feature | Description | Effort |
|---|---|---|
| Template builder | Create custom workout templates with exercises, sets, reps, and rest periods | L |
| Built-in templates | Ship with common routines (Push/Pull/Legs, Upper/Lower, Full Body, HIIT) | M |
| Interval timer | Configurable work/rest interval timer with haptic and audio cues | M |
| Exercise library | Searchable database of common exercises with muscle group tags | L |
| Template sharing | Share templates with friends via deep links | S |
| Watch timer sync | Mirror interval timer on Apple Watch with haptic alerts | M |

**Estimated total effort:** 8–10 weeks

---

## v1.4 — Gym Finder

**Goal:** Discover nearby gyms using MapKit and help users add them as monitored locations.

| Feature | Description | Effort |
|---|---|---|
| Nearby gym search | Use MapKit / MKLocalSearch to find gyms, fitness centers, and studios near the user | M |
| Map view | Full-screen map showing nearby gyms with pins and distance | M |
| One-tap add | Add a discovered gym to monitored locations with a single tap | S |
| Gym details | Show hours, ratings, and contact info (from MapKit POI data) | S |
| Directions | Open Apple Maps with directions to a selected gym | S |
| Favorite gyms | Mark gyms as favorites for quick access across devices | S |

**Estimated total effort:** 4–5 weeks

---

## v1.5 — Progress Photos

**Goal:** Visual body transformation tracking with comparison tools.

| Feature | Description | Effort |
|---|---|---|
| Photo capture | In-app camera with pose guide overlay (front, side, back) | M |
| Photo timeline | Chronological grid of progress photos with date stamps | M |
| Side-by-side compare | Swipe between two dates to see visual progress | M |
| Privacy vault | Photos stored in app sandbox, not in Camera Roll (opt-in export) | S |
| Body measurements | Optional manual logging of weight, body fat %, and measurements | M |
| Progress chart | Graph weight/measurements over time alongside session frequency | M |

**Estimated total effort:** 6–8 weeks

---

## v2.0 — AI Personal Trainer

**Goal:** Intelligent workout suggestions based on your history, goals, and patterns.

| Feature | Description | Effort |
|---|---|---|
| Workout analysis | Analyze session history for patterns (frequency, preferred days, duration trends) | L |
| Smart suggestions | Recommend workout type and duration based on recent activity and recovery time | XL |
| Goal setting | Set goals (weight loss, muscle gain, endurance) and get tailored session recommendations | L |
| Rest day alerts | Notify user when they should rest based on consecutive intense sessions | M |
| Weekly plan | Auto-generate a weekly workout plan based on goals and availability | XL |
| Natural language coach | Chat interface for workout questions ("What should I do today?") using on-device ML | XL |
| Adaptive difficulty | Adjust recommendations based on session completion rate and feedback | L |

**Estimated total effort:** 12–16 weeks

---

## Effort Key

| Size | Time |
|---|---|
| **S** (Small) | < 1 week |
| **M** (Medium) | 1–2 weeks |
| **L** (Large) | 2–4 weeks |
| **XL** (Extra Large) | 4+ weeks |

---

*Last updated: March 24, 2026*
