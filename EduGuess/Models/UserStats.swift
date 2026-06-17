import Foundation

// MARK: - Firestore Codable Models

struct FirebaseUser: Codable {
    var name: String
    var email: String
    var avatar: String
    var createdAt: Date
    var stats: UserStats
}

struct UserStats: Codable {
    var totalGames: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var totalScore: Int = 0
    var bestScore: Int = 0

    var winRate: Double {
        totalGames > 0 ? Double(wins) / Double(totalGames) : 0
    }
}

struct FirebaseGameSession: Codable {
    var userId: String
    var userName: String
    var characterName: String
    var won: Bool
    var score: Int
    var questionsAsked: [String]
    var answers: [Bool]
    var timestamp: Date
}

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { userId }
    var userId: String
    var name: String
    var score: Int
    var wins: Int
    var games: Int
}

// MARK: - Scoring

enum GameScoring {
    static func calculateScore(questionsAsked: Int, won: Bool) -> Int {
        guard won else { return 0 }
        let totalAttributes = 38
        return max(10, (totalAttributes - questionsAsked) * 10)
    }
}

// MARK: - UserDefaults Keys

enum AuthKeys {
    static let isLoggedIn = "auth_isLoggedIn"
    static let userUID = "auth_userUID"
    static let userName = "auth_userName"
    static let userEmail = "auth_userEmail"
}
