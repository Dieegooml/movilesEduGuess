import Foundation
import FirebaseAuth
import GoogleSignIn
import FacebookLogin
import AuthenticationServices
import UIKit
import CryptoKit
import Security

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
        try await result.user.sendEmailVerification()
        await MainActor.run {
            self.user = result.user
            self.cacheSession(result.user)
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
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

    /// Generates a cryptographically random nonce string (original, unhashed).
    private func randomNonceString() throws -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = 32
        while remaining > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, 16, &randomBytes)
            guard status == errSecSuccess else {
                throw AuthError.noAuthenticationToken
            }
            for byte in randomBytes {
                guard remaining > 0 else { break }
                let index = Int(byte) % charset.count
                result.append(charset[index])
                remaining -= 1
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    @MainActor
    func signInWithFacebook() async throws {
        let loginManager = LoginManager()
        let rawNonce = try randomNonceString()
        let hashedNonce = sha256(rawNonce)

        guard let config = LoginConfiguration(
            permissions: ["email", "public_profile"],
            tracking: .limited,
            nonce: hashedNonce
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
            rawNonce: rawNonce
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        self.user = authResult.user
        cacheSession(authResult.user)
    }

    // MARK: - Sign In with Apple

    @MainActor
    func signInWithApple(authorization: ASAuthorization, nonce: String?) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.noCredential
        }

        // Use the original nonce (not hashed) for Firebase verification
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: identityToken,
            rawNonce: nonce ?? ""
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        
        // Update display name if available (only provided on first sign-in)
        if let fullName = appleIDCredential.fullName,
           let givenName = fullName.givenName {
            let displayName = givenName + (fullName.familyName.map { " \($0)" } ?? "")
            if authResult.user.displayName == nil || authResult.user.displayName!.isEmpty {
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try? await changeRequest.commitChanges()
            }
        }

        self.user = authResult.user
        cacheSession(authResult.user)
    }

    // MARK: - Account Deletion

    /// Attempts to delete the current Firebase Auth user.
    /// Note: For social providers, this may fail if the session is too old.
    /// Callers should handle the error and prompt for re-authentication if needed.
    func deleteAccount() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.noCredential
        }
        try await currentUser.delete()
        user = nil
        clearCache()
    }

    /// Re-authenticates an email/password user before sensitive operations.
    func reauthenticate(email: String, password: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.noCredential
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await currentUser.reauthenticate(with: credential)
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
