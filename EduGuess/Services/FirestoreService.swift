import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private let usersCollection = "users"
    private let sessionsCollection = "game_sessions"
    private let leaderboardCollection = "leaderboard"

    // MARK: - Users

    func createUser(uid: String, name: String, email: String) async throws {
        let user = FirebaseUser(
            name: name,
            email: email,
            avatar: "person.circle.fill",
            createdAt: Date(),
            stats: UserStats()
        )
        try db.collection(usersCollection).document(uid).setData(from: user)
    }

    func fetchUser(uid: String) async throws -> FirebaseUser? {
        let doc = try await db.collection(usersCollection).document(uid).getDocument()
        return try doc.data(as: FirebaseUser.self)
    }

    // MARK: - Daily Challenge

    func saveDailyScore(userId: String, userName: String, avatar: String, characterName: String, questionsAsked: Int, score: Int) async throws {
        let key = dailyKey()
        try await db
            .collection("daily_challenges")
            .document(key)
            .collection("scores")
            .document(userId)
            .setData([
                "userId": userId,
                "userName": userName,
                "userAvatar": avatar,
                "characterName": characterName,
                "questionsAsked": questionsAsked,
                "score": score,
                "timestamp": FieldValue.serverTimestamp(),
            ])
    }

    func fetchDailyLeaderboard() async throws -> [DailyScore] {
        let key = dailyKey()
        let snapshot = try await db
            .collection("daily_challenges")
            .document(key)
            .collection("scores")
            .order(by: "score", descending: true)
            .limit(to: 50)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: DailyScore.self) }
    }

    func hasPlayedDaily(userId: String) async throws -> Bool {
        let key = dailyKey()
        let doc = try await db
            .collection("daily_challenges")
            .document(key)
            .collection("scores")
            .document(userId)
            .getDocument()
        return doc.exists
    }

    private func dailyKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func updateUserProfile(uid: String, name: String?, avatar: String?) async throws {
        let ref = db.collection(usersCollection).document(uid)
        var data: [String: Any] = [:]
        if let name { data["name"] = name }
        if let avatar { data["avatar"] = avatar }
        guard !data.isEmpty else { return }
        try await ref.updateData(data)
    }

    // MARK: - Stats

    func updateStats(uid: String, won: Bool, score: Int) async throws {
        let ref = db.collection(usersCollection).document(uid)
        try await db.runTransaction { transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(ref)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            var data = snapshot.data() ?? [:]
            var stats = data["stats"] as? [String: Any] ?? [:]

            stats["totalGames"] = (stats["totalGames"] as? Int ?? 0) + 1
            if won {
                stats["wins"] = (stats["wins"] as? Int ?? 0) + 1
            } else {
                stats["losses"] = (stats["losses"] as? Int ?? 0) + 1
            }
            stats["totalScore"] = (stats["totalScore"] as? Int ?? 0) + score
            let currentBest = stats["bestScore"] as? Int ?? 0
            if score > currentBest {
                stats["bestScore"] = score
            }

            let totalScore = stats["totalScore"] as? Int ?? 0
            transaction.updateData([
                "stats": stats,
                "totalScore": totalScore
            ], forDocument: ref)
            return nil
        }
    }

    private func fetchUserName(uid: String) async throws -> String {
        // Try to get name from Firebase Auth (local session)
        if let displayName = Auth.auth().currentUser?.displayName, !displayName.isEmpty {
            return displayName
        }
        // Fallback: try to read from other auth providers or existing user doc
        return "Usuario"
    }

    // MARK: - Game Sessions

    func saveSession(_ session: FirebaseGameSession) async throws {
        try db.collection(sessionsCollection).addDocument(from: session)
    }

    func fetchUserSessions(uid: String, limit: Int = 20) async throws -> [FirebaseGameSession] {
        let snapshot = try await db.collection(sessionsCollection)
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: FirebaseGameSession.self) }
    }

    // MARK: - Account Deletion

    /// Deletes all user data from Firestore. Should be called before deleting Firebase Auth account.
    func deleteAllUserData(uid: String) async throws {
        // 1. Delete user document
        try await db.collection(usersCollection).document(uid).delete()

        // 2. Delete all game sessions
        let sessionsSnapshot = try await db.collection(sessionsCollection)
            .whereField("userId", isEqualTo: uid)
            .getDocuments()
        for doc in sessionsSnapshot.documents {
            try await doc.reference.delete()
        }

        // 3. Delete all achievements
        let achievementsSnapshot = try await db.collection(usersCollection).document(uid).collection("achievements").getDocuments()
        for doc in achievementsSnapshot.documents {
            try await doc.reference.delete()
        }

        // 4. Delete daily challenge scores using a collection group query
        let scoresSnapshot = try await db.collectionGroup("scores")
            .whereField("userId", isEqualTo: uid)
            .getDocuments()
        for scoreDoc in scoresSnapshot.documents {
            try await scoreDoc.reference.delete()
        }
    }

    // MARK: - Leaderboard

    func fetchLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection(usersCollection)
            .order(by: "totalScore", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> LeaderboardEntry? in
            guard let fbUser = try? doc.data(as: FirebaseUser.self) else { return nil }
            return LeaderboardEntry(
                userId: doc.documentID,
                name: fbUser.name,
                avatar: fbUser.avatar,
                score: fbUser.stats.totalScore,
                wins: fbUser.stats.wins,
                games: fbUser.stats.totalGames,
                losses: fbUser.stats.losses,
                bestScore: fbUser.stats.bestScore,
                streak: fbUser.streak.currentStreak
            )
        }
    }

    func fetchTopWeekly(limit: Int = 50) async throws -> [LeaderboardEntry] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let snapshot = try await db.collection(sessionsCollection)
            .whereField("timestamp", isGreaterThan: weekAgo)
            .whereField("won", isEqualTo: true)
            .limit(to: limit * 10)
            .getDocuments()

        var scores: [String: (name: String, score: Int, wins: Int, games: Int)] = [:]
        for doc in snapshot.documents {
            guard let session = try? doc.data(as: FirebaseGameSession.self) else { continue }
            var entry = scores[session.userId] ?? (session.userName, 0, 0, 0)
            entry.score += session.score
            entry.wins += session.won ? 1 : 0
            entry.games += 1
            scores[session.userId] = entry
        }

        return scores
            .map { LeaderboardEntry(userId: $0.key, name: $0.value.name, avatar: "person.circle.fill", score: $0.value.score, wins: $0.value.wins, games: $0.value.games, losses: 0, bestScore: 0, streak: 0) }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }
}
