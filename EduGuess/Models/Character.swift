//
//  Character.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation

struct Character: Identifiable {

    let id = UUID()

    let name: String
    let image: String

    let attributes: [String: Bool]
}
