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
    @State private var containerError = false
    @AppStorage("appTheme") private var appTheme: Theme = .system
    @State private var container: ModelContainer?

    init() {
        let schema = Schema([SDCharacter.self, SDQuestion.self, SDGameSession.self])
        let config = ModelConfiguration("EduGuess", schema: schema)
        if let c = try? ModelContainer(for: schema, configurations: [config]) {
            _container = State(initialValue: c)
        } else {
            _containerError = State(initialValue: true)
        }
    }

    var body: some Scene {
        WindowGroup {
            if containerError {
                errorView
            } else if let container {
                Group {
                    if isReady {
                        if authVM.isAuthenticated && !authVM.isNewSession {
                            NavigationStack {
                                HomeView()
                            }
                        } else if authVM.isAuthenticated {
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
            } else {
                loadingView
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

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text("Error al cargar la base de datos")
                .font(.title2)
                .fontWeight(.bold)
            Text("Reinstala la app o contacta al soporte.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
