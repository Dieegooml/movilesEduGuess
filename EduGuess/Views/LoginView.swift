import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isRegistering = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture { UIApplication.shared.endEditing() }

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "brain.head.profile")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.white)

                Text("EduGuess")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(.white)

                Text(isRegistering ? "Crear cuenta" : "Iniciar sesión")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))

                VStack(spacing: 12) {
                    if isRegistering {
                        TextField("Nombre", text: $name)
                            .textFieldStyle()
                    }

                    TextField("Correo electrónico", text: $email)
                        .textFieldStyle()
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Contraseña", text: $password)
                        .textFieldStyle()
                }
                .padding(.horizontal, 30)

                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.white)
                        .font(.caption)
                        .padding(.horizontal)
                }

                Button {
                    if isRegistering {
                        authVM.signUp(email: email, password: password, name: name)
                    } else {
                        authVM.signIn(email: email, password: password)
                    }
                } label: {
                    HStack {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.orange)
                        }
                        Text(isRegistering ? "Registrarse" : "Entrar")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(18)
                }
                .padding(.horizontal, 30)
                .disabled(authVM.isLoading)

                VStack(spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.4))
                        .padding(.horizontal, 30)

                    AppleSignInButton { request in
                        // Request configured in coordinator
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            authVM.signInWithApple(authorization: authorization)
                        case .failure(let error):
                            authVM.errorMessage = error.localizedDescription
                        }
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 30)

                    Button {
                        authVM.signInWithGoogle()
                    } label: {
                        HStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.orange)
                            } else {
                                Image(systemName: "globe")
                            }
                            Text("Continuar con Google")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 30)
                    .disabled(authVM.isLoading)

                    Button {
                        authVM.signInWithFacebook()
                    } label: {
                        HStack {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.blue)
                            } else {
                                Image(systemName: "f.square.fill")
                            }
                            Text("Continuar con Facebook")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(18)
                    }
                    .padding(.horizontal, 30)
                    .disabled(authVM.isLoading)
                }

                if !isRegistering {
                    Button {
                        authVM.resetPassword(email: email)
                    } label: {
                        Text("¿Olvidaste tu contraseña?")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                }

                Button {
                    isRegistering.toggle()
                    authVM.errorMessage = nil
                } label: {
                    Text(isRegistering ? "¿Ya tienes cuenta? Inicia sesión" : "¿No tienes cuenta? Regístrate")
                        .foregroundColor(.white)
                        .font(.subheadline)
                }

                Spacer()
            }
        }
    }
}

// MARK: - Sign in with Apple Button

struct AppleSignInButton: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .white)
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.didTapButton),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let parent: AppleSignInButton

        init(_ parent: AppleSignInButton) {
            self.parent = parent
        }

        @objc func didTapButton() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            parent.onRequest(request)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window available")
            }
            return window
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            parent.onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            parent.onCompletion(.failure(error))
        }
    }
}

// MARK: - Extensions

extension TextField {
    func textFieldStyle() -> some View {
        self
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.white)
            .tint(.white)
            .autocorrectionDisabled()
    }
}

extension SecureField {
    func textFieldStyle() -> some View {
        self
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
