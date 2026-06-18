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

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var authVM = AuthViewModel.shared
    @State private var isReady = false
    @AppStorage("appTheme") private var appTheme: Theme = .system
    let container: ModelContainer

    init() {
        let schema = Schema([SDCharacter.self, SDQuestion.self, SDGameSession.self])
        let config = ModelConfiguration("EduGuess", schema: schema)
        container = try! ModelContainer(for: schema, configurations: [config])
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isReady {
                    if authVM.isAuthenticated {
                        NavigationStack {
                            SplashView()
                        }
                    } else {
                        LoginView()
                    }
                } else {
                    loadingView
                }
            }
            .modelContainer(container)
            .preferredColorScheme(appTheme.colorScheme)
            .onAppear {
                authVM.configure()
                isReady = true
                let context = container.mainContext
                SeedManager.seedIfNeeded(context: context)
                Task {
                    await NotificationService.shared.requestPermission()
                    await NotificationService.shared.scheduleDailyChallengeReminder()
                }
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }
    }
}
