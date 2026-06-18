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

    init(name: String, image: String = "", attributes: [String: Bool]) {
        self.name = name
        self.image = image
        self.attributesData = (try? JSONEncoder().encode(attributes)) ?? Data()
    }

    var attributes: [String: Bool] {
        get {
            guard let data = attributesData else { return [:] }
            return (try? JSONDecoder().decode([String: Bool].self, from: data)) ?? [:]
        }
        set {
            attributesData = (try? JSONEncoder().encode(newValue))
        }
    }

    func toCharacter() -> Character {
        Character(name: name, image: image, attributes: attributes)
    }
}
