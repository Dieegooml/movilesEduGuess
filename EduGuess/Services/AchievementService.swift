import Foundation
import FirebaseFirestore

struct Achievement: Codable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let requirement: String
}

struct UserAchievement: Codable, Identifiable {
    @DocumentID var id: String?
    let achievementId: String
    let name: String
    let icon: String
    let description: String
    let unlockedAt: Date
}

struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastPlayedDate: String = ""
}

let allAchievements: [Achievement] = [
    Achievement(id: "first_game", name: "Primera Partida", icon: "play.circle.fill", description: "Completa tu primera partida", requirement: "Jugar 1 partida"),
    Achievement(id: "first_win", name: "Primera Victoria", icon: "star.circle.fill", description: "Gana tu primera partida", requirement: "Ganar 1 partida"),
    Achievement(id: "streak_3", name: "Racha de 3", icon: "flame.fill", description: "Juega 3 días seguidos el desafío diario", requirement: "Racha de 3 días"),
    Achievement(id: "streak_7", name: "Racha de 7", icon: "flame.fill", description: "Juega 7 días seguidos el desafío diario", requirement: "Racha de 7 días"),
    Achievement(id: "streak_30", name: "Racha de 30", icon: "flame.fill", description: "Juega 30 días seguidos el desafío diario", requirement: "Racha de 30 días"),
    Achievement(id: "win_10", name: "Adivinador", icon: "brain.head.profile", description: "Gana 10 partidas", requirement: "Ganar 10 partidas"),
    Achievement(id: "win_50", name: "Maestro", icon: "graduationcap.fill", description: "Gana 50 partidas", requirement: "Ganar 50 partidas"),
    Achievement(id: "quick_guess", name: "Mente Rápida", icon: "bolt.fill", description: "Adivina en 5 preguntas o menos", requirement: "5 preguntas o menos"),
    Achievement(id: "daily_7", name: "Dedicado", icon: "calendar.badge.clock", description: "Completa 7 desafíos diarios", requirement: "7 desafíos diarios"),
    Achievement(id: "score_500", name: "Leyenda", icon: "crown.fill", description: "Acumula 500 puntos en total", requirement: "500 puntos acumulados"),
]

actor AchievementService {
    static let shared = AchievementService()

    private let db = Firestore.firestore()
    private var cachedUnlocked: (data: [UserAchievement], timestamp: Date)?
    private var cachedStreak: (data: StreakData, timestamp: Date)?
    private let cacheTTL: TimeInterval = 60

    func checkAndUnlock(uid: String, stats: UserStats, streak: StreakData, questionsCount: Int = 0) async -> [UserAchievement] {
        let existing = await fetchUnlocked(uid: uid)
        let existingIds = Set(existing.map { $0.achievementId })
        var newOnes: [UserAchievement] = []

        let checks: [(String, () -> Bool)] = [
            ("first_game", { stats.totalGames >= 1 }),
            ("first_win", { stats.wins >= 1 }),
            ("streak_3", { streak.currentStreak >= 3 }),
            ("streak_7", { streak.currentStreak >= 7 }),
            ("streak_30", { streak.currentStreak >= 30 }),
            ("win_10", { stats.wins >= 10 }),
            ("win_50", { stats.wins >= 50 }),
            ("quick_guess", { questionsCount > 0 && questionsCount <= 5 }),
            ("daily_7", { streak.currentStreak >= 7 }),
            ("score_500", { stats.totalScore >= 500 }),
        ]

        for (id, condition) in checks {
            guard !existingIds.contains(id), condition() else { continue }
            if let achievement = allAchievements.first(where: { $0.id == id }) {
                let ua = UserAchievement(
                    achievementId: achievement.id,
                    name: achievement.name,
                    icon: achievement.icon,
                    description: achievement.description,
                    unlockedAt: Date()
                )
                newOnes.append(ua)
                try? await db.collection("users").document(uid).collection("achievements").addDocument(from: ua)
            }
        }

        if !newOnes.isEmpty {
            cachedUnlocked = nil
        }
        return newOnes
    }

    func fetchUnlocked(uid: String) async -> [UserAchievement] {
        if let cached = cachedUnlocked, Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.data
        }
        let snapshot = try? await db.collection("users").document(uid).collection("achievements")
            .order(by: "unlockedAt", descending: true)
            .getDocuments()
        let result = snapshot?.documents.compactMap { try? $0.data(as: UserAchievement.self) } ?? []
        cachedUnlocked = (result, Date())
        return result
    }

    // MARK: - Streaks

    func updateStreak(uid: String) async -> StreakData {
        let ref = db.collection("users").document(uid)
        do {
            try await db.runTransaction { transaction, errorPointer in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(ref)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                var data = snapshot.data() ?? [:]
                var streak = data["streak"] as? [String: Any] ?? [:]
                let currentStreak = streak["currentStreak"] as? Int ?? 0
                let longestStreak = streak["longestStreak"] as? Int ?? 0
                let lastPlayedDate = streak["lastPlayedDate"] as? String ?? ""

                let today = self.dailyKey()
                let yesterday = self.dailyKey(offset: -1)

                var newStreak = currentStreak
                if lastPlayedDate == today {
                    // Already played today, no change needed
                    return nil
                } else if lastPlayedDate == yesterday {
                    newStreak = currentStreak + 1
                } else {
                    newStreak = 1
                }

                var newLongest = max(longestStreak, newStreak)

                transaction.updateData([
                    "streak.currentStreak": newStreak,
                    "streak.longestStreak": newLongest,
                    "streak.lastPlayedDate": today,
                ], forDocument: ref)
                return nil
            }
        } catch {
            print("Transaction failed updating streak: \(error)")
        }

        // Fetch and return updated streak
        let updatedDoc = try? await ref.getDocument()
        let result = (try? updatedDoc?.data(as: FirebaseUser.self))?.streak ?? StreakData()
        cachedStreak = nil
        return result
    }

    func fetchStreak(uid: String) async -> StreakData {
        if let cached = cachedStreak, Date().timeIntervalSince(cached.timestamp) < cacheTTL {
            return cached.data
        }
        let doc = try? await db.collection("users").document(uid).getDocument()
        let result = (try? doc?.data(as: FirebaseUser.self))?.streak ?? StreakData()
        cachedStreak = (result, Date())
        return result
    }

    private func dailyKey(offset: Int = 0) -> String {
        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}