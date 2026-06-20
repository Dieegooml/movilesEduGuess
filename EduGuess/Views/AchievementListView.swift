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
                StreakBadge(label: "Racha actual", value: streak.currentStreak, icon: "flame.fill", color: .orange)
                StreakBadge(label: "Mejor racha", value: streak.longestStreak, icon: "crown.fill", color: .yellow)
            }

            // Achievements
            Text("Logros")
                .font(.headline)
                .foregroundColor(.white)

            if isLoading {
                ProgressView()
                    .tint(.white)
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
                    .foregroundColor(.white)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.1))
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
                .foregroundColor(unlocked ? .yellow : .white.opacity(0.3))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(unlocked ? .white : .white.opacity(0.4))
                Text(achievement.requirement)
                    .font(.caption2)
                    .foregroundColor(unlocked ? .white.opacity(0.7) : .white.opacity(0.3))
            }

            Spacer()

            if unlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.2))
                    .font(.caption)
            }
        }
        .padding(12)
        .background(Color.white.opacity(unlocked ? 0.15 : 0.05))
        .cornerRadius(12)
        .opacity(unlocked ? 1 : 0.6)
    }
}
