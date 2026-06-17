import Foundation
import FirebaseFirestore

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
            avatar: "",
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

    func saveDailyScore(userId: String, userName: String, characterName: String, questionsAsked: Int, score: Int) async throws {
        let key = dailyKey()
        try await db
            .collection("daily_challenges")
            .document(key)
            .collection("scores")
            .document(userId)
            .setData([
                "userId": userId,
                "userName": userName,
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

    // MARK: - Stats

    func updateStats(uid: String, won: Bool, score: Int) async throws {
        let ref = db.collection(usersCollection).document(uid)
        let _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let doc = try transaction.getDocument(ref)
                guard let fbUser = try? doc.data(as: FirebaseUser.self) else {
                    errorPointer?.pointee = NSError(domain: "EduGuess", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                    return nil
                }
                var stats = fbUser.stats
                stats.totalGames += 1
                if won { stats.wins += 1 } else { stats.losses += 1 }
                stats.totalScore += score
                if score > stats.bestScore { stats.bestScore = score }
                try transaction.setData(from: stats, forDocument: ref)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
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

    // MARK: - Leaderboard

    func fetchLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection(usersCollection)
            .order(by: "stats.totalScore", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            guard let fbUser = try? doc.data(as: FirebaseUser.self) else { return nil }
            return LeaderboardEntry(
                userId: doc.documentID,
                name: fbUser.name,
                score: fbUser.stats.totalScore,
                wins: fbUser.stats.wins,
                games: fbUser.stats.totalGames
            )
        }
    }

    func fetchTopWeekly(limit: Int = 50) async throws -> [LeaderboardEntry] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let snapshot = try await db.collection(sessionsCollection)
            .whereField("timestamp", isGreaterThan: weekAgo)
            .whereField("won", isEqualTo: true)
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
            .map { LeaderboardEntry(userId: $0.key, name: $0.value.name, score: $0.value.score, wins: $0.value.wins, games: $0.value.games) }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }
}
