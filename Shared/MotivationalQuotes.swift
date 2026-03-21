import Foundation

enum MotivationalQuotes {
    static let quotes: [String] = [
        "The only bad workout is the one that didn't happen.",
        "Your body can stand almost anything. It's your mind you have to convince.",
        "Discipline is choosing between what you want now and what you want most.",
        "The pain you feel today will be the strength you feel tomorrow.",
        "Don't limit your challenges — challenge your limits.",
        "Sweat is just fat crying.",
        "Consistency beats intensity. Show up.",
        "You don't have to be extreme, just consistent.",
        "The gym is not about getting better than someone else. It's about getting better than you used to be.",
        "Wake up. Work out. Look hot. Kick ass.",
        "Sore today, strong tomorrow.",
        "If it doesn't challenge you, it doesn't change you.",
        "Fall in love with taking care of yourself.",
        "Success isn't given. It's earned — in the gym, on the track, in the field.",
        "The difference between try and triumph is a little umph.",
        "Push yourself because no one else is going to do it for you.",
        "Strive for progress, not perfection.",
        "Your health is an investment, not an expense.",
        "One hour of exercise is 4% of your day. No excuses.",
        "Motivation gets you started. Habit keeps you going.",
        "Be stronger than your excuses.",
        "The best project you'll ever work on is you.",
        "Don't stop when you're tired. Stop when you're done.",
        "Hustle for that muscle.",
        "Train insane or remain the same.",
        "Good things come to those who sweat.",
        "The iron never lies. 200lbs is always 200lbs.",
        "You're only one workout away from a good mood.",
        "Champions train, losers complain.",
        "Your body hears everything your mind says. Stay positive."
    ]

    /// Returns a deterministic quote based on the current day
    static var todaysQuote: String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % quotes.count
        return quotes[index]
    }
}
