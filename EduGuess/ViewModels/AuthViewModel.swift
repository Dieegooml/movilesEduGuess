import Foundation
import SwiftUI

@Observable
final class AuthViewModel {
    static let shared = AuthViewModel()

    var isAuthenticated = false
    var isNewSession = true
    var isLoading = false
    var errorMessage: String?

    var userUID: String? { FirebaseAuthService.shared.user?.uid }
    var userName: String {
        let stored = UserDefaults.standard.string(forKey: "displayName") ?? ""
        if !stored.isEmpty { return stored }
        return FirebaseAuthService.shared.user?.displayName ?? "Usuario"
    }
    var userEmail: String { FirebaseAuthService.shared.user?.email ?? "" }

    /// Returns a stable anonymous user ID for guests who haven't logged in.
    var effectiveUserId: String {
        userUID ?? guestUserId
    }

    private var guestUserId: String {
        let key = "guest_user_id"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    private init() {}

    func configure() {
        FirebaseAuthService.shared.configure()
        isAuthenticated = FirebaseAuthService.shared.isAuthenticated
        isNewSession = false
    }

    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await FirebaseAuthService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isAuthenticated = true
                    isNewSession = true
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
            defer {
                await MainActor.run { isLoading = false }
            }
            do {
                try await FirebaseAuthService.shared.signUp(email: email, password: password, name: name)
                guard let uid = FirebaseAuthService.shared.user?.uid else {
                    await MainActor.run { errorMessage = "No se pudo obtener el UID del usuario." }
                    return
                }
                try await FirestoreService.shared.createUser(uid: uid, name: name, email: email)
                await MainActor.run {
                    isAuthenticated = true
                    isNewSession = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        Task {
            defer {
                await MainActor.run { isLoading = false }
            }
            do {
                try await FirebaseAuthService.shared.signInWithGoogle()
                guard let uid = FirebaseAuthService.shared.user?.uid else {
                    await MainActor.run { errorMessage = "No se pudo obtener el UID del usuario." }
                    return
                }
                let name = FirebaseAuthService.shared.user?.displayName ?? "Usuario"
                let email = FirebaseAuthService.shared.user?.email ?? ""
                try? await FirestoreService.shared.createUser(uid: uid, name: name, email: email)
                await MainActor.run {
                    isAuthenticated = true
                    isNewSession = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signInWithFacebook() {
        isLoading = true
        errorMessage = nil
        Task {
            defer {
                await MainActor.run { isLoading = false }
            }
            do {
                try await FirebaseAuthService.shared.signInWithFacebook()
                guard let uid = FirebaseAuthService.shared.user?.uid else {
                    await MainActor.run { errorMessage = "No se pudo obtener el UID del usuario." }
                    return
                }
                let name = FirebaseAuthService.shared.user?.displayName ?? "Usuario"
                let email = FirebaseAuthService.shared.user?.email ?? ""
                try? await FirestoreService.shared.createUser(uid: uid, name: name, email: email)
                await MainActor.run {
                    isAuthenticated = true
                    isNewSession = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func resetPassword(email: String) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await FirebaseAuthService.shared.resetPassword(email: email)
                await MainActor.run {
                    errorMessage = "Te hemos enviado un correo para restablecer tu contraseña."
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
