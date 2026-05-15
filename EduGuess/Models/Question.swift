//
//  Question.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation

struct Question: Identifiable {

    let id = UUID()

    let text: String
    let attributeKey: String
}
