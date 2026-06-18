import Foundation
import SwiftData

struct DailyScore: Codable, Identifiable {
    var id: String { "\(userId)_\(DailyChallengeService.dateFormatter.string(from: Date()))" }
    let userId: String
    let userName: String
    var userAvatar: String
    let characterName: String
    let questionsAsked: Int
    let score: Int
    let timestamp: Date?

    init(userId: String, userName: String, userAvatar: String = "person.circle.fill", characterName: String, questionsAsked: Int, score: Int) {
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.characterName = characterName
        self.questionsAsked = questionsAsked
        self.score = score
        self.timestamp = Date()
    }
}

actor DailyChallengeService {
    static let shared = DailyChallengeService()

    static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func characterForToday(context: ModelContext) -> Character? {
        let service = DataService()
        let all = service.fetchCharacters(context: context)
        guard !all.isEmpty else { return nil }

        let dayNumber = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        let index = dayNumber % all.count
        return all[index]
    }

    func saveScore(userId: String, userName: String, avatar: String, characterName: String, questionsAsked: Int, score: Int) async {
        do {
            try await FirestoreService.shared.saveDailyScore(
                userId: userId,
                userName: userName,
                avatar: avatar,
                characterName: characterName,
                questionsAsked: questionsAsked,
                score: score
            )
        } catch {
            print("Failed to save daily score: \(error)")
        }
    }

    func leaderboard() async -> [DailyScore] {
        (try? await FirestoreService.shared.fetchDailyLeaderboard()) ?? []
    }

    func hasPlayedToday(userId: String) async -> Bool {
        (try? await FirestoreService.shared.hasPlayedDaily(userId: userId)) ?? false
    }
}
