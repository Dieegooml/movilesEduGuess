import Foundation
import SwiftUI

@Observable
final class AuthViewModel {
    static let shared = AuthViewModel()

    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?

    var userUID: String? { FirebaseAuthService.shared.user?.uid }
    var userName: String {
        let stored = UserDefaults.standard.string(forKey: "displayName") ?? ""
        if !stored.isEmpty { return stored }
        return FirebaseAuthService.shared.user?.displayName ?? "Usuario"
    }
    var userEmail: String { FirebaseAuthService.shared.user?.email ?? "" }

    private init() {}

    func configure() {
        FirebaseAuthService.shared.configure()
        isAuthenticated = FirebaseAuthService.shared.isAuthenticated
    }

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await FirebaseAuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func signUp(email: String, password: String, name: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await FirebaseAuthService.shared.signUp(email: email, password: password, name: name)
                guard let uid = FirebaseAuthService.shared.user?.uid else { return }
                try await FirestoreService.shared.createUser(uid: uid, name: name, email: email)
                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await FirebaseAuthService.shared.signInWithGoogle()
                guard let uid = FirebaseAuthService.shared.user?.uid else { return }
                let name = FirebaseAuthService.shared.user?.displayName ?? "Usuario"
                let email = FirebaseAuthService.shared.user?.email ?? ""
                try? await FirestoreService.shared.createUser(uid: uid, name: name, email: email)
                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func signInWithFacebook() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await FirebaseAuthService.shared.signInWithFacebook()
                guard let uid = FirebaseAuthService.shared.user?.uid else { return }
                let name = FirebaseAuthService.shared.user?.displayName ?? "Usuario"
                let email = FirebaseAuthService.shared.user?.email ?? ""
                try? await FirestoreService.shared.createUser(uid: uid, name: name, email: email)
                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func signOut() {
        FirebaseAuthService.shared.signOut()
        isAuthenticated = false
    }
}
