import Foundation

/// Tracks how useful each attribute has been at narrowing the candidate pool
/// across games. Persisted lightly in UserDefaults and used by AIService to
/// boost attributes that historically led to correct guesses.
struct AttributeStats: Codable {
    var usedCount: Int = 0
    var guessSuccessCount: Int = 0
    var poolReductionSum: Double = 0

    var averageReduction: Double {
        usedCount > 0 ? poolReductionSum / Double(usedCount) : 0
    }

    var successRate: Double {
        usedCount > 0 ? Double(guessSuccessCount) / Double(usedCount) : 0
    }
}

final class AttributeLearningService {
    static let shared = AttributeLearningService()

    private let defaultsKey = "attribute_learning_stats"
    private var stats: [String: AttributeStats] = [:]
    private let lock = NSLock()

    private init() {
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([String: AttributeStats].self, from: data) else {
            return
        }
        stats = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    func recordUse(attributeKey: String, poolBefore: Int, poolAfter: Int, ledToGuess: Bool, guessCorrect: Bool) {
        lock.lock()
        defer { lock.unlock() }

        var entry = stats[attributeKey] ?? AttributeStats()
        entry.usedCount += 1
        let reduction = poolBefore > 0 ? Double(poolBefore - poolAfter) / Double(poolBefore) : 0
        entry.poolReductionSum += reduction
        if ledToGuess && guessCorrect {
            entry.guessSuccessCount += 1
        }
        stats[attributeKey] = entry
        save()
    }

    func boosts(for keys: Set<String>) -> [String: Double] {
        lock.lock()
        defer { lock.unlock() }

        var result: [String: Double] = [:]
        for key in keys {
            guard let entry = stats[key] else { continue }
            // Cap the boost so it doesn't dominate entropy-based selection
            result[key] = min(0.25, entry.successRate * 0.3 + entry.averageReduction * 0.15)
        }
        return result
    }

    func topUsefulAttributes(limit: Int = 20) -> [String] {
        lock.lock()
        defer { lock.unlock() }

        return stats
            .sorted { $0.value.successRate + $0.value.averageReduction > $1.value.successRate + $1.value.averageReduction }
            .prefix(limit)
            .map { $0.key }
    }
}
