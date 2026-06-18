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
        let doc = try await ref.getDocument()
        var fbUser: FirebaseUser

        if let existing = try? doc.data(as: FirebaseUser.self) {
            fbUser = existing
        } else {
            let name = try await fetchUserName(uid: uid)
            fbUser = FirebaseUser(name: name, email: "", avatar: "person.circle.fill", createdAt: Date(), stats: UserStats())
        }

        fbUser.stats.totalGames += 1
        if won { fbUser.stats.wins += 1 } else { fbUser.stats.losses += 1 }
        fbUser.stats.totalScore += score
        if score > fbUser.stats.bestScore { fbUser.stats.bestScore = score }
        try ref.setData(from: fbUser)
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

    // MARK: - Leaderboard

    func fetchLeaderboard(limit: Int = 50) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collection(usersCollection).getDocuments()

        let entries = snapshot.documents.compactMap { doc -> LeaderboardEntry? in
            guard let fbUser = try? doc.data(as: FirebaseUser.self) else { return nil }
            return LeaderboardEntry(
                userId: doc.documentID,
                name: fbUser.name,
                avatar: fbUser.avatar,
                score: fbUser.stats.totalScore,
                wins: fbUser.stats.wins,
                games: fbUser.stats.totalGames
            )
        }
        return entries.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
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
            .map { LeaderboardEntry(userId: $0.key, name: $0.value.name, avatar: "person.circle.fill", score: $0.value.score, wins: $0.value.wins, games: $0.value.games) }
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }
}
