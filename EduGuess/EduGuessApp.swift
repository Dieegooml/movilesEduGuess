//
//  EduGuessApp.swift
//  EduGuess
//
//  Created by Daniela Nicol Salazar Quina on 15/05/26.
//

import SwiftUI
import SwiftData

@main
struct EduGuessApp: App {

    let container: ModelContainer

    init() {
        let schema = Schema([SDCharacter.self, SDQuestion.self])
        let config = ModelConfiguration("EduGuess", schema: schema)
        container = try! ModelContainer(for: schema, configurations: [config])
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .modelContainer(container)
        }
    }
}
