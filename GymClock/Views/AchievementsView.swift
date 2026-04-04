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
                    progressHeader
                    
                    if !achievementManager.nextToUnlock.isEmpty {
                        almostThereSection
                    }
                    
                    rarityFilter
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    
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
            // Trophy shelf with rarity breakdown
            HStack(spacing: 0) {
                ForEach(Array(AchievementRarity.allCases.enumerated()), id: \.element.rawValue) { _, rarity in
                    let count = achievementManager.achievements.filter { $0.rarity == rarity && $0.isUnlocked }.count
                    let total = achievementManager.achievements.filter { $0.rarity == rarity }.count
                    
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(rarity.color.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Text("\(count)")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(count > 0 ? rarity.color : .secondary)
                        }
                        Text(rarity.rawValue)
                            .font(.caption2.bold())
                            .foregroundStyle(count > 0 ? rarity.color : .secondary)
                        Text("\(count)/\(total)")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            
            Divider()
            
            // Overall progress ring
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: achievementManager.totalCount > 0
                              ? Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount)
                              : 0)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: achievementManager.unlockedCount)
                    
                    Text("🏆")
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Progress")
                        .font(.headline)
                    
                    Text("\(achievementManager.unlockedCount) of \(achievementManager.totalCount) unlocked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    let percentage = achievementManager.totalCount > 0
                        ? Int(Double(achievementManager.unlockedCount) / Double(achievementManager.totalCount) * 100)
                        : 0
                    Text("\(percentage)% Complete")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Almost There Section
    
    private var almostThereSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text("Almost There!")
                    .font(.headline)
            }
            
            ForEach(Array(achievementManager.nextToUnlock.prefix(3))) { achievement in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(achievement.rarity.color.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Text(achievement.icon)
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(achievement.title)
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(Int(achievement.progress * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(achievement.rarity.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(achievement.rarity.color.opacity(0.1), in: Capsule())
                        }
                        
                        // Custom progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(achievement.rarity.color)
                                    .frame(width: geo.size.width * achievement.progress, height: 6)
                                    .animation(.spring(response: 0.6), value: achievement.progress)
                            }
                        }
                        .frame(height: 6)
                        
                        Text(achievement.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
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
                    withAnimation(.spring(response: 0.3)) { selectedRarity = nil }
                }
                
                ForEach(AchievementRarity.allCases, id: \.rawValue) { rarity in
                    FilterChip(label: rarity.rawValue, isSelected: selectedRarity == rarity, color: rarity.color) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedRarity = selectedRarity == rarity ? nil : rarity
                        }
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
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
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
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? color : color.opacity(0.1),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
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
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon with rarity glow
            ZStack {
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.rarity.glowColor)
                        .frame(width: 60, height: 60)
                        .blur(radius: 10)
                }
                
                Circle()
                    .fill(achievement.isUnlocked
                          ? achievement.rarity.color.opacity(0.12)
                          : Color(.systemGray6))
                    .frame(width: 56, height: 56)
                
                Text(achievement.icon)
                    .font(.system(size: 32))
                    .grayscale(achievement.isUnlocked ? 0 : 1)
                    .opacity(achievement.isUnlocked ? 1 : 0.35)
            }
            
            Text(achievement.title)
                .font(.subheadline.bold())
                .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            // Rarity badge
            Text(achievement.rarity.rawValue.uppercased())
                .font(.system(size: 9, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(achievement.isUnlocked ? achievement.rarity.color : .gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (achievement.isUnlocked ? achievement.rarity.color : .gray).opacity(0.12),
                    in: Capsule()
                )
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Progress bar for locked achievements
            if !achievement.isUnlocked && achievement.progress > 0 {
                VStack(spacing: 3) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Color(.systemGray5))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(achievement.rarity.color)
                                .frame(width: geo.size.width * achievement.progress, height: 5)
                        }
                    }
                    .frame(height: 5)
                    
                    Text("\(Int(achievement.progress * 100))%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            
            if let date = achievement.unlockedDate {
                Text(date, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(
            achievement.isUnlocked
                ? achievement.rarity.color.opacity(0.06)
                : Color(.systemGray6).opacity(0.5),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    achievement.isUnlocked
                        ? achievement.rarity.color.opacity(0.25)
                        : Color(.systemGray4).opacity(0.3),
                    lineWidth: achievement.isUnlocked ? 1.5 : 0.5
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
            
            VStack(spacing: 24) {
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
                        .frame(width: 110, height: 110)
                        .blur(radius: glowRadius)
                    
                    Circle()
                        .fill(achievement.rarity.color.opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    Text(achievement.icon)
                        .font(.system(size: 64))
                        .scaleEffect(iconScale)
                }
                
                // Rarity label
                Text(achievement.rarity.rawValue.uppercased())
                    .font(.caption.bold())
                    .tracking(4)
                    .foregroundStyle(achievement.rarity.color)
                
                VStack(spacing: 6) {
                    Text("Achievement Unlocked!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    
                    Text(achievement.title)
                        .font(.title3.bold())
                        .foregroundStyle(achievement.rarity.color)
                    
                    Text(achievement.description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // Share button
                ShareLink(
                    item: ShareManager.generateAchievementShareText(achievement: achievement)
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(achievement.rarity.color, in: Capsule())
                    .shadow(color: achievement.rarity.color.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            .padding(36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28))
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
