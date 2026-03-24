import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var achievementManager: AchievementManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Progress Header
                    progressHeader
                    
                    // Achievement Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(achievementManager.achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🏆 Progress")
                    .font(.headline)
                Spacer()
                Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
            
            ProgressView(value: Double(achievementManager.unlockedCount), total: Double(achievementManager.totalCount))
                .tint(.green)
                .scaleEffect(y: 2)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Text(achievement.icon)
                .font(.system(size: 40))
                .grayscale(achievement.isUnlocked ? 0 : 1)
                .opacity(achievement.isUnlocked ? 1 : 0.4)
            
            Text(achievement.title)
                .font(.subheadline.bold())
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if let date = achievement.unlockedDate {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            achievement.isUnlocked
                ? Color.green.opacity(0.08)
                : Color.gray.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.isUnlocked ? Color.green.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Celebration Overlay

struct AchievementCelebrationOverlay: View {
    let achievement: Achievement
    @Binding var isShowing: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isShowing = false
                }
            
            VStack(spacing: 20) {
                // Confetti emojis
                HStack(spacing: 20) {
                    ForEach(["🎉", "🎊", "✨", "🎉", "🎊"], id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 30))
                            .offset(y: confettiOffset)
                    }
                }
                
                Text(achievement.icon)
                    .font(.system(size: 80))
                
                Text("Achievement Unlocked!")
                    .font(.title2.bold())
                    .foregroundStyle(.green)
                
                Text(achievement.title)
                    .font(.title3.bold())
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                // Share button
                ShareLink(
                    item: ShareManager.generateAchievementShareText(achievement: achievement)
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(.green, in: Capsule())
                }
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.0)) {
                confettiOffset = 0
            }
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AchievementManager())
}
