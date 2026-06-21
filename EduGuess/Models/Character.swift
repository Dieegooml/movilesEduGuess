//
//  Character.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation
import SwiftData

// MARK: - In-Memory Representation
struct Character: Identifiable {

    let id: UUID = UUID()
    let name: String
    let image: String
    let attributes: [String: Bool]
}

// MARK: - SwiftData Model
@Model
final class SDCharacter {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var image: String
    var attributesData: Data?

    /// Cached decoded attributes to avoid decoding JSON on every access.
    /// Transient so it is not persisted by SwiftData.
    @Transient private var cachedAttributes: [String: Bool]?

    init(name: String, image: String = "", attributes: [String: Bool]) {
        self.name = name
        self.image = image
        self.attributesData = (try? JSONEncoder().encode(attributes)) ?? Data()
        self.cachedAttributes = attributes
    }

    var attributes: [String: Bool] {
        get {
            if let cached = cachedAttributes { return cached }
            guard let data = attributesData else { return [:] }
            let decoded = (try? JSONDecoder().decode([String: Bool].self, from: data)) ?? [:]
            cachedAttributes = decoded
            return decoded
        }
        set {
            cachedAttributes = newValue
            attributesData = (try? JSONEncoder().encode(newValue))
        }
    }

    func toCharacter() -> Character {
        Character(name: name, image: image, attributes: attributes)
    }
}
