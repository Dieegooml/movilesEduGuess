import Foundation
import SwiftData

struct ImportedCharacter: Codable {
    let name: String
    let attributes: [String: Bool]
}

actor CharacterImportService {
    static let shared = CharacterImportService()

    func fetchCharacters(from url: URL) async throws -> [ImportedCharacter] {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([ImportedCharacter].self, from: data)
    }

    func importCharacters(_ imported: [ImportedCharacter], context: ModelContext) -> (imported: Int, skipped: Int) {
        var importedCount = 0
        var skippedCount = 0

        let existingDescriptor = FetchDescriptor<SDCharacter>()
        let existingNames = Set((try? context.fetch(existingDescriptor))?.map { $0.name } ?? [])

        for character in imported {
            let name = character.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else {
                skippedCount += 1
                continue
            }
            guard !existingNames.contains(name) else {
                skippedCount += 1
                continue
            }

            let newCharacter = SDCharacter(name: name, attributes: character.attributes)
            context.insert(newCharacter)
            importedCount += 1
        }

        try? context.save()
        return (importedCount, skippedCount)
    }
}
