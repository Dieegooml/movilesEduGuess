import Foundation
import FirebaseAuth
import GoogleSignIn
import FacebookLogin
import UIKit
import CryptoKit

enum AuthError: LocalizedError {
    case noRootViewController
    case noIDToken
    case noCredential
    case facebookCancelled
    case noAuthenticationToken

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "No se pudo obtener la vista principal."
        case .noIDToken:
            return "No se pudo obtener el token de Google."
        case .noCredential:
            return "No se pudo obtener la credencial de autenticación."
        case .facebookCancelled:
            return "Inicio de sesión con Facebook cancelado."
        case .noAuthenticationToken:
            return "No se pudo obtener el token de autenticación de Facebook."
        }
    }
}

@Observable
final class FirebaseAuthService {
    static let shared = FirebaseAuthService()

    private(set) var user: User?
    var isAuthenticated: Bool { user != nil }

    private var isConfigured = false

    private init() {}

    func configure() {
        guard !isConfigured else { return }
        isConfigured = true
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            cacheSession(currentUser)
        } else if UserDefaults.standard.bool(forKey: AuthKeys.isLoggedIn) {
            clearCache()
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.user = result.user
            self.cacheSession(result.user)
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        await MainActor.run {
            self.user = result.user
            self.cacheSession(result.user)
        }
    }

    // MARK: - Google Sign In

    @MainActor
    func signInWithGoogle() async throws {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first?
            .rootViewController else {
            throw AuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.noIDToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        self.user = authResult.user
        cacheSession(authResult.user)
    }

    // MARK: - Facebook Limited Login

    /// Generates a cryptographically random nonce string for Limited Login.
    private func generateNonce() -> String {
        let data = SHA256.hash(data: Data(UUID().uuidString.utf8))
        return data.compactMap { String(format: "%02x", $0) }.prefix(32).joined()
    }

    @MainActor
    func signInWithFacebook() async throws {
        let loginManager = LoginManager()
        let nonce = generateNonce()

        guard let config = LoginConfiguration(
            permissions: ["email", "public_profile"],
            tracking: .limited,
            nonce: nonce
        ) else {
            throw AuthError.noCredential
        }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?
            .windows
            .first?
            .rootViewController else {
            throw AuthError.noRootViewController
        }

        let result: LoginResult = await withCheckedContinuation { continuation in
            loginManager.logIn(
                viewController: rootVC,
                configuration: config
            ) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .cancelled:
            throw AuthError.facebookCancelled
        case .failed(let error):
            throw error
        case .success:
            break
        }

        guard let authToken = AuthenticationToken.current?.tokenString else {
            throw AuthError.noAuthenticationToken
        }

        let credential = OAuthProvider.credential(
            providerID: .facebook,
            idToken: authToken,
            rawNonce: nonce
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        self.user = authResult.user
        cacheSession(authResult.user)
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        user = nil
        clearCache()
    }

    // MARK: - Session Cache

    private func cacheSession(_ user: User) {
        UserDefaults.standard.set(true, forKey: AuthKeys.isLoggedIn)
        UserDefaults.standard.set(user.uid, forKey: AuthKeys.userUID)
        UserDefaults.standard.set(user.displayName ?? "Usuario", forKey: AuthKeys.userName)
        UserDefaults.standard.set(user.email ?? "", forKey: AuthKeys.userEmail)
    }

    private func clearCache() {
        UserDefaults.standard.set(false, forKey: AuthKeys.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: AuthKeys.userUID)
        UserDefaults.standard.removeObject(forKey: AuthKeys.userName)
        UserDefaults.standard.removeObject(forKey: AuthKeys.userEmail)
    }
}
