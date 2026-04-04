import Foundation
import WatchKit

/// Centralized haptic feedback manager for the watch app
final class HapticManager {
    static let shared = HapticManager()
    
    /// User preference for haptic feedback
    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hapticFeedbackEnabled")
        }
    }
    
    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") as? Bool ?? true
    }
    
    // MARK: - Workout Haptics
    
    /// Play success haptic when workout starts
    func workoutStarted() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.start)
    }
    
    /// Play stop haptic when workout ends
    func workoutEnded() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.stop)
    }
    
    /// Play success haptic when a goal is completed
    func goalCompleted() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.success)
        // Double tap for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.notification)
        }
    }
    
    // MARK: - Navigation Haptics
    
    /// Subtle click for digital crown scroll detents
    func crownDetent() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.click)
    }
    
    /// Direction up haptic
    func directionUp() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.directionUp)
    }
    
    /// Direction down haptic
    func directionDown() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.directionDown)
    }
    
    // MARK: - Feedback Haptics
    
    /// Generic success feedback
    func success() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.success)
    }
    
    /// Generic failure feedback
    func failure() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.failure)
    }
    
    /// Subtle notification
    func notification() {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(.notification)
    }
}
