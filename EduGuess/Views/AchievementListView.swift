import SwiftUI
import FirebaseFirestore

struct AchievementListView: View {
    let isOwnProfile: Bool

    @State private var unlocked: [UserAchievement] = []
    @State private var streak: StreakData = StreakData()
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Streak section
            HStack(spacing: 20) {
                StreakBadge(label: "Racha actual", value: streak.currentStreak, icon: "flame.fill", color: AppTheme.primaryOrange)
                StreakBadge(label: "Mejor racha", value: streak.longestStreak, icon: "crown.fill", color: AppTheme.primaryGold)
            }

            // Achievements
            Text("Logros")
                .font(.headline)
                .foregroundColor(AppTheme.primaryText)

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Text("Cargando logros...")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                    ForEach(allAchievements) { achievement in
                        let isUnlocked = unlocked.contains(where: { $0.achievementId == achievement.id })
                        AchievementCard(achievement: achievement, unlocked: isUnlocked)
                    }
                }
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        let uid = AuthViewModel.shared.effectiveUserId
        async let u = AchievementService.shared.fetchUnlocked(uid: uid)
        async let s = AchievementService.shared.fetchStreak(uid: uid)
        unlocked = await u
        streak = await s
        isLoading = false
    }
}

private struct StreakBadge: View {
    let label: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryText)
                Text(label)
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

private struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(unlocked ? AppTheme.primaryGold : AppTheme.primaryText.opacity(0.3))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(unlocked ? AppTheme.primaryText : AppTheme.primaryText.opacity(0.4))
                Text(achievement.requirement)
                    .font(.caption2)
                    .foregroundColor(unlocked ? AppTheme.secondaryText : AppTheme.secondaryText.opacity(0.5))
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(AppTheme.successGreen)
                    .font(.caption)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(AppTheme.primaryText.opacity(0.2))
                    .font(.caption)
            }
        }
        .padding(12)
        .background(AppTheme.cardSurface.opacity(unlocked ? 1 : 0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(unlocked ? AppTheme.cardBorder : Color.clear, lineWidth: 1)
        )
        .cornerRadius(12)
        .opacity(unlocked ? 1 : 0.6)
    }
}
