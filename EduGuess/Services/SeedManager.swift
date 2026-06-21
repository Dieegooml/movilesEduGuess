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

        importCharacters(from: data, context: context)
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
        let allAttributeKeys = Set(AttributeDefinition.pool.map(\.key))
        var imported = 0

        for char in characters {
            // Support both sparse (only true values) and full attribute dictionaries.
            let fullAttributes: [String: Bool]
            let isFullFormat = char.attributes.count >= allAttributeKeys.count
                || char.attributes.values.contains(false)
            if isFullFormat {
                // Full format: use as-is.
                fullAttributes = char.attributes
            } else {
                // Sparse format: expand with false defaults.
                var expanded = Dictionary(uniqueKeysWithValues: allAttributeKeys.map { ($0, false) })
                for (key, value) in char.attributes where value == true {
                    expanded[key] = true
                }
                fullAttributes = expanded
            }

            service.addCharacter(
                name: char.name,
                image: char.image,
                attributes: fullAttributes,
                context: context,
                autoSave: false
            )
            imported += 1
        }

        // Single batch save after all inserts.
        do {
            try context.save()
            print("SeedManager: Imported \(imported) characters from seed file.")
        } catch {
            print("SeedManager: Failed to save seeded characters: \(error)")
        }
    }
}
