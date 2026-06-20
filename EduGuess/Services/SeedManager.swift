import Foundation
import SwiftData

/// Loads seed data from a bundled JSON file on first launch.
struct SeedManager {

    private static let seedFileName = "characters_seed"

    /// Call this once at app startup (e.g., from `EduGuessApp.init()` or `.onAppear`).
    static func seedIfNeeded(context: ModelContext) {
        let service = DataService()
        let count = service.knownCharacterCount(context: context)
        guard count == 0 else { return }

        guard let url = Bundle.main.url(forResource: seedFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("SeedManager: No seed file found (\(seedFileName).json) – skipping.")
            return
        }

        // Perform import in a background task to avoid blocking the main thread
        Task(priority: .background) {
            importCharacters(from: data, context: context)
        }
    }

    // MARK: - Import

    private struct SeedCharacter: Codable {
        let name: String
        let image: String
        let attributes: [String: Bool]
    }

    private static func importCharacters(from data: Data, context: ModelContext) {
        let decoder = JSONDecoder()
        guard let characters = try? decoder.decode([SeedCharacter].self, from: data) else {
            print("SeedManager: Failed to decode seed JSON.")
            return
        }

        let service = DataService()
        var imported = 0
        for char in characters {
            service.addCharacter(
                name: char.name,
                image: char.image,
                attributes: char.attributes,
                context: context
            )
            imported += 1
        }
        print("SeedManager: Imported \(imported) characters from seed file.")
    }
}
