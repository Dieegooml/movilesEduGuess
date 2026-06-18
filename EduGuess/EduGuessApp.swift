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
    @State private var containerErrorMessage = ""
    @AppStorage("appTheme") private var appTheme: Theme = .system
    @State private var container: ModelContainer?
    @State private var isRetrying = false

    init() {
        let schema = Schema([SDCharacter.self, SDQuestion.self, SDGameSession.self])
        let config = ModelConfiguration("EduGuess", schema: schema)
        do {
            let c = try ModelContainer(for: schema, configurations: [config])
            _container = State(initialValue: c)
        } catch {
            _containerError = State(initialValue: true)
            _containerErrorMessage = State(initialValue: error.localizedDescription)
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
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Error al cargar la base de datos")
                .font(.title2)
                .fontWeight(.bold)

            if !containerErrorMessage.isEmpty {
                Text(containerErrorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Text("Esto puede ocurrir tras una actualización o si los datos se corrompieron.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(role: .destructive) {
                resetStore()
            } label: {
                HStack {
                    if isRetrying {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "trash")
                    }
                    Text("Borrar datos locales y reintentar")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(14)
            }
            .disabled(isRetrying)
            .padding(.horizontal, 30)
        }
        .padding()
    }

    private func resetStore() {
        isRetrying = true
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsPath.appendingPathComponent("default.store")
        try? FileManager.default.removeItem(at: storeURL)
        // Also try the named store
        let namedStoreURL = documentsPath.appendingPathComponent("EduGuess.store")
        try? FileManager.default.removeItem(at: namedStoreURL)
        // Retry initialization
        let schema = Schema([SDCharacter.self, SDQuestion.self, SDGameSession.self])
        let config = ModelConfiguration("EduGuess", schema: schema)
        do {
            let c = try ModelContainer(for: schema, configurations: [config])
            container = c
            containerError = false
            containerErrorMessage = ""
            isRetrying = false
        } catch {
            containerErrorMessage = error.localizedDescription
            isRetrying = false
        }
    }
}
