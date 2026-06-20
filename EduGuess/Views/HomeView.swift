import SwiftUI

struct HomeView: View {
    @State private var authVM = AuthViewModel.shared
    @State private var buttonsAppeared = false
    @State private var showTutorial = false
    @State private var showSignOutAlert = false
    @State private var showOnboarding = false
    @State private var showOfflineBanner = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.9), Color.red.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Offline banner
                if showOfflineBanner {
                    OfflineBanner(onRetry: {
                        // Retry action handled by monitor
                    })
                    .monitor()
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                mainContent
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    NavigationLink {
                        HowToPlayView()
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.white)
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(.white)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundColor(.white)
                    }

                    if authVM.isAuthenticated {
                        Button {
                            showSignOutAlert = true
                        } label: {
                            Text("Salir")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .alert("Cerrar sesión", isPresented: $showSignOutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) { authVM.signOut() }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
        .fullScreenCover(isPresented: $showTutorial) {
            NavigationStack {
                HowToPlayView()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            // Check onboarding
            if !hasCompletedOnboarding {
                showOnboarding = true
                hasCompletedOnboarding = true
            }

            // Animate buttons
            buttonsAppeared = false
            withAnimation(.easeOut(duration: 0.1)) {
                buttonsAppeared = true
            }

            // Show tutorial for returning users who haven't seen it
            if authVM.isAuthenticated && !hasSeenTutorial && hasCompletedOnboarding {
                showTutorial = true
                hasSeenTutorial = true
            }

            // Monitor network
            NetworkMonitor.shared.onChange { isConnected in
                DispatchQueue.main.async {
                    withAnimation(.spring(duration: 0.3)) {
                        showOfflineBanner = !isConnected
                    }
                }
            }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "brain")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, options: .nonRepeating, value: buttonsAppeared)

                Text("EduGuess")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.white)

                Text("Piensa en un personaje y la IA intentará adivinarlo")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal)
            }

            if authVM.isAuthenticated {
                Text("Bienvenido, \(authVM.userName)")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.subheadline)
            }

            VStack(spacing: 16) {
                menuButton(
                    icon: "star.fill",
                    title: "Desafío Diario",
                    subtitle: "Un personaje nuevo cada día",
                    style: .card,
                    offset: buttonsAppeared ? 0 : -200
                ) {
                    DailyChallengeView()
                }

                menuButton(
                    icon: "play.fill",
                    title: "Comenzar",
                    subtitle: "La IA intentará adivinar tu personaje",
                    style: .gradient,
                    offset: buttonsAppeared ? 0 : 200
                ) {
                    QuestionView()
                }

                menuButton(
                    icon: "trophy.fill",
                    title: "Ranking",
                    subtitle: "Compara tus puntajes",
                    style: .outline,
                    offset: buttonsAppeared ? 0 : 200
                ) {
                    LeaderboardView()
                }
            }
            .padding(.horizontal, 30)

            Spacer()
        }
    }

    private enum ButtonStyle {
        case card, gradient, outline
    }

    private func menuButton<V: View>(
        icon: String,
        title: String,
        subtitle: String,
        style: ButtonStyle,
        offset: CGFloat,
        @ViewBuilder destination: () -> V
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack {
                ZStack {
                    switch style {
                    case .card:
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 36, height: 36)
                    case .gradient:
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                    case .outline:
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                    }
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(style == .gradient ? .orange : .white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text(subtitle)
                        .font(.caption)
                        .opacity(0.8)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundColor(style == .card ? .orange : .white)
            .padding(16)
            .background(
                Group {
                    switch style {
                    case .card:
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    case .gradient:
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 4)
                    case .outline:
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    }
                }
            )
        }
        .offset(x: offset)
        .opacity(offset == 0 ? 1 : 0)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: buttonsAppeared)
        .pressEffect()
    }
}

// MARK: - Press Effect Modifier

struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                        HapticManager.shared.impact(.light)
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    func pressEffect() -> some View {
        modifier(PressEffectModifier())
    }
}

// MARK: - Haptic Manager

final class HapticManager {
    static let shared = HapticManager()

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}
