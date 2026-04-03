import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var achievementManager: AchievementManager
    @State private var selectedRarity: AchievementRarity? = nil
    @State private var showConfetti = false
    
    private var filteredAchievements: [Achievement] {
        if let rarity = selectedRarity {
            return achievementManager.achievements.filter { $0.rarity == rarity }
        }
        return achievementManager.achievements
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Progress Header
                    progressHeader
                    
                    // "Almost There" section
                    if !achievementManager.nextToUnlock.isEmpty {
                        almostThereSection
                    }
                    
                    // Rarity Filter
                    rarityFilter
                    
                    // Achievement Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    
                    // Stats footer
                    statsFooter
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Trophy shelf
            HStack(spacing: 0) {
                ForEach(Array(AchievementRarity.allCases.enumerated()), id: \.element.rawValue) { _, rarity in
                    let count = achievementManager.achievements.filter { $0.rarity == rarity && $0.isUnlocked }.count
                    let total = achievementManager.achievements.filter { $0.rarity == rarity }.count
                    
                    VStack(spacing: 4) {
                        Text("\(count)/\(total)")
                            .font(.subheadline.bold())
                            .foregroundStyle(rarity.color)
                        Text(rarity.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Overall progress
            HStack {
                Text("🏆 Total Progress")
                    .font(.headline)
                Spacer()
                Text("\(achievementManager.unlockedCount)/\(achievementManager.totalCount)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
            
            ProgressView(value: Double(achievementManager.unlockedCount), total: Double(achievementManager.totalCount))
                .tint(.green)
                .scaleEffect(y: 2)
            
            // Completion percentage
            let percentage = achievementManager.totalCount > 0
                ? Int(Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount) * 100)
                : 0
            Text("\(percentage)% Complete")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Almost There Section
    
    private var almostThereSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text("Almost There!")
                    .font(.headline)
            }
            
            ForEach(Array(achievementManager.nextToUnlock.prefix(3))) { achievement in
                HStack(spacing: 12) {
                    Text(achievement.icon)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(achievement.title)
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(Int(achievement.progress * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(achievement.rarity.color)
                        }
                        
                        ProgressView(value: achievement.progress)
                            .tint(achievement.rarity.color)
                        
                        Text(achievement.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Rarity Filter
    
    private var rarityFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedRarity == nil) {
                    selectedRarity = nil
                }
                
                ForEach(AchievementRarity.allCases, id: \.rawValue) { rarity in
                    FilterChip(label: rarity.rawValue, isSelected: selectedRarity == rarity, color: rarity.color) {
                        selectedRarity = selectedRarity == rarity ? nil : rarity
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Footer
    
    private var statsFooter: some View {
        let unlocked = achievementManager.achievements.filter(\.isUnlocked)
        let latestUnlock = unlocked.compactMap(\.unlockedDate).max()
        
        return Group {
            if let latest = latestUnlock {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Last unlock: \(latest, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .green
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? color : color.opacity(0.1),
                    in: Capsule()
                )
        }
    }
}

// MARK: - Achievement Rarity CaseIterable

extension AchievementRarity: CaseIterable {
    static var allCases: [AchievementRarity] = [.common, .rare, .epic, .legendary]
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: Achievement
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon with rarity glow
            ZStack {
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.rarity.glowColor)
                        .frame(width: 56, height: 56)
                        .blur(radius: 8)
                }
                
                Text(achievement.icon)
                    .font(.system(size: 40))
                    .grayscale(achievement.isUnlocked ? 0 : 1)
                    .opacity(achievement.isUnlocked ? 1 : 0.4)
            }
            
            Text(achievement.title)
                .font(.subheadline.bold())
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
            
            // Rarity badge
            Text(achievement.rarity.rawValue)
                .font(.system(size: 9).bold())
                .foregroundStyle(achievement.isUnlocked ? achievement.rarity.color : .gray)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    (achievement.isUnlocked ? achievement.rarity.color : .gray).opacity(0.15),
                    in: Capsule()
                )
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Progress bar for locked achievements
            if !achievement.isUnlocked && achievement.progress > 0 {
                VStack(spacing: 2) {
                    ProgressView(value: achievement.progress)
                        .tint(achievement.rarity.color)
                    Text("\(Int(achievement.progress * 100))%")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            
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
                ? achievement.rarity.color.opacity(0.08)
                : Color.gray.opacity(0.05),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked
                        ? achievement.rarity.color.opacity(0.3)
                        : Color.gray.opacity(0.15),
                    lineWidth: achievement.isUnlocked ? 1.5 : 1
                )
        )
    }
}

// MARK: - Celebration Overlay

struct AchievementCelebrationOverlay: View {
    let achievement: Achievement
    @Binding var isShowing: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiPhase: CGFloat = 0
    @State private var iconScale: CGFloat = 0.3
    @State private var glowRadius: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowing = false
                    }
                }
            
            VStack(spacing: 20) {
                // Animated confetti burst
                ZStack {
                    ForEach(0..<12, id: \.self) { index in
                        let angle = Double(index) * (360.0 / 12.0)
                        let emoji = ["🎉", "🎊", "✨", "⭐", "💫", "🌟"][index % 6]
                        Text(emoji)
                            .font(.system(size: 20))
                            .offset(
                                x: cos(angle * .pi / 180) * (40 + confettiPhase * 60),
                                y: sin(angle * .pi / 180) * (40 + confettiPhase * 60) - confettiPhase * 30
                            )
                            .opacity(max(0, 1 - confettiPhase * 0.8))
                    }
                }
                
                // Achievement icon with glow
                ZStack {
                    Circle()
                        .fill(achievement.rarity.glowColor)
                        .frame(width: 100, height: 100)
                        .blur(radius: glowRadius)
                    
                    Text(achievement.icon)
                        .font(.system(size: 80))
                        .scaleEffect(iconScale)
                }
                
                // Rarity label
                Text(achievement.rarity.rawValue.uppercased())
                    .font(.caption.bold())
                    .tracking(3)
                    .foregroundStyle(achievement.rarity.color)
                
                Text("Achievement Unlocked!")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text(achievement.title)
                    .font(.title3.bold())
                    .foregroundStyle(achievement.rarity.color)
                
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
                    .background(achievement.rarity.color, in: Capsule())
                }
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 1.2)) {
                confettiPhase = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowRadius = 20
            }
        }
    }
}

#Preview {
    AchievementsView()
        .environmentObject(AchievementManager())
}
