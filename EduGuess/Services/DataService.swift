//
//  DataService.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import Foundation

class DataService {

    // MARK: - Load Characters

    func loadCharacters() -> [Character] {

        return [

            Character(
                name: "Harry Potter",
                image: "harry",
                attributes: [
                    "usesMagic": true,
                    "wearsGlasses": true,
                    "isReal": false,
                    "isMale": true
                ]
            ),

            Character(
                name: "Hermione Granger",
                image: "hermione",
                attributes: [
                    "usesMagic": true,
                    "wearsGlasses": false,
                    "isReal": false,
                    "isMale": false
                ]
            ),

            Character(
                name: "Albert Einstein",
                image: "einstein",
                attributes: [
                    "usesMagic": false,
                    "wearsGlasses": false,
                    "isReal": true,
                    "isMale": true
                ]
            )
        ]
    }

    // MARK: - Load Questions

    func loadQuestions() -> [Question] {

        return [

            Question(
                text: "¿Tu personaje usa magia?",
                attributeKey: "usesMagic"
            ),

            Question(
                text: "¿Tu personaje usa lentes?",
                attributeKey: "wearsGlasses"
            ),

            Question(
                text: "¿Tu personaje es real?",
                attributeKey: "isReal"
            ),

            Question(
                text: "¿Tu personaje es hombre?",
                attributeKey: "isMale"
            )
        ]
    }
}
